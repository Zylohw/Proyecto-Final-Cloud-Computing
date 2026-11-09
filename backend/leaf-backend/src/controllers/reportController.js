const pool = require('../config/db');
const PDFDocument = require('pdfkit');

const fs = require('fs/promises');
const path = require('path');
const crypto = require('crypto');

const { PutObjectCommand, GetObjectCommand, HeadObjectCommand } = require('@aws-sdk/client-s3');
const { getSignedUrl } = require('@aws-sdk/s3-request-presigner');
const { s3, BUCKET } = require('../config/s3');

const REPORTES_DIR = path.join(__dirname, '../../private/reportes');
const PREFIJO_S3 = 'reportes/';
const URL_EXPIRA_SEGUNDOS = 300;

// Guarda el PDF en S3 si hay bucket configurado; si no, en disco (entorno local).
async function guardarPdf(nombreArchivo, pdfBuffer)
{
    if (s3)
    {
        await s3.send(new PutObjectCommand(
            {
                Bucket: BUCKET,
                Key: PREFIJO_S3 + nombreArchivo,
                Body: pdfBuffer,
                ContentType: 'application/pdf'
            }));
        return;
    }

    await fs.mkdir(REPORTES_DIR, { recursive: true });

    const archivoTemporal = path.join(REPORTES_DIR, `${crypto.randomUUID()}.tmp`);

    try
    {
        await fs.writeFile(archivoTemporal, pdfBuffer);
        await fs.rename(archivoTemporal, path.join(REPORTES_DIR, nombreArchivo));
    }
    catch (error)
    {
        await fs.rm(archivoTemporal, { force: true }).catch(() => {});
        throw error;
    }
}

async function emitirReporte(req, res)
{
    const { id } = req.params;

    if (!/^[1-9]\d*$/.test(id))
    {
        return res.status(400).json({ mensaje: 'ID de reporte inválido' });
    }

    try
    {
        const resultado = await pool.query(`SELECT r.id, r.titulo, r.descripcion, r.fecha, r.pdf,
                                                  c.sector, c.numero,
                                                  d.medida_tomada, d.contenido, d.fecha AS fecha_lectura
                                            FROM reporte r, reciben rc, casa c, datos d
                                            WHERE rc.reporte_id = r.id
                                            AND c.id = rc.casa_id
                                            AND d.reporte_id = r.id
                                            AND d.estado = TRUE
                                            AND d.id = (   SELECT d2.id
                                                          FROM datos d2
                                                          WHERE d2.reporte_id = r.id
                                                          AND d2.estado = TRUE
                                                          ORDER BY d2.fecha DESC, d2.id DESC
                                                          LIMIT 1 )
                                            AND r.id = $1
                                            AND r.usuario_id = $2
                                            AND r.estado = TRUE`,
                                            [id, req.usuario.id] );

        if (resultado.rows.length === 0)
        {
            return res.status(404).json({ mensaje: 'Reporte no encontrado o sin lectura registrada' });
        }

        const reporte = resultado.rows[0];

        if (reporte.pdf)
        {
            return res.status(409).json({ mensaje: 'El reporte ya fue emitido' });
        }

        const documento = new PDFDocument({ size: 'A4', margin: 50 });

        const partes = [];

        documento.on('data', parte => { partes.push(parte); });

        const pdfGenerado = new Promise((resolve, reject) =>
            {
                documento.on('end', () => { resolve(Buffer.concat(partes)); });
                documento.on('error', reject);
            });

        documento.fontSize(25).text('LEAF', { align: 'center' });
        documento.moveDown();
        documento.fontSize(18).text('Reporte de lectura de contador de agua', { align: 'center' });
        documento.moveDown(2);
        documento.fontSize(13);
        documento.text(`Reporte No.: ${reporte.id}`);
        documento.moveDown();
        documento.text(`Sector: ${reporte.sector}`);
        documento.moveDown();
        documento.text(`Vivienda: ${reporte.numero}`);
        documento.moveDown();
        documento.text(`Fecha de lectura: ${new Date(reporte.fecha_lectura).toLocaleString('es-GT',
            {
                timeZone: 'America/Guatemala'
            })}`);
        documento.moveDown();
        documento.fontSize(16).text('Medición registrada');
        documento.moveDown();
        documento.fontSize(20).text(`${reporte.medida_tomada} m³`);
        documento.moveDown(2);
        documento.fontSize(13).text('Observaciones:');
        documento.moveDown();
        documento.text(reporte.contenido || 'Sin observaciones adicionales');
        documento.moveDown(3);
        documento.fontSize(10).text('Documento generado mediante Leaf.', { align: 'center' });

        documento.end();

        const pdfBuffer = await pdfGenerado;

        const nombreArchivo = `reporte-${reporte.id}.pdf`;

        await guardarPdf(nombreArchivo, pdfBuffer);

        const actualizado = await pool.query(`UPDATE reporte
                                              SET pdf = $1
                                              WHERE id = $2
                                              AND usuario_id = $3
                                              AND estado = TRUE
                                              AND pdf IS NULL
                                              RETURNING id, titulo, pdf, fecha`,
                                              [nombreArchivo, reporte.id, req.usuario.id] );

        if (actualizado.rows.length === 0)
        {
            return res.status(409).json({ mensaje: 'El reporte ya fue emitido o cambió de estado' });
        }

        return res.json(
            {
                mensaje: 'Reporte PDF generado correctamente',
                reporte: actualizado.rows[0]
            });
    }
    catch (error)
    {
        console.error('Error en emitirReporte:', error);
        return res.status(500).json({ mensaje: 'Error al generar el reporte PDF' });
    }
}

// Firma un enlace temporal de S3 para un PDF. Devuelve null si el archivo no existe.
async function generarUrlDescarga(nombreArchivo)
{
    const llave = PREFIJO_S3 + nombreArchivo;

    try
    {
        await s3.send(new HeadObjectCommand({ Bucket: BUCKET, Key: llave }));
    }
    catch (error)
    {
        if (error.name === 'NotFound' || error.$metadata?.httpStatusCode === 404)
        {
            return null;
        }
        throw error;
    }

    return getSignedUrl(s3, new GetObjectCommand(
        {
            Bucket: BUCKET,
            Key: llave,
            ResponseContentType: 'application/pdf',
            ResponseContentDisposition: `attachment; filename="${nombreArchivo}"`
        }),
        { expiresIn: URL_EXPIRA_SEGUNDOS });
}

async function responderDescarga(res, nombreArchivo)
{
    if (!nombreArchivo)
    {
        return res.status(404).json({ mensaje: 'El reporte aún no tiene un PDF emitido' });
    }

    const url = await generarUrlDescarga(nombreArchivo);

    if (!url)
    {
        return res.status(404).json({ mensaje: 'El archivo PDF no se encuentra en el almacenamiento' });
    }

    return res.json(
        {
            mensaje: 'Enlace de descarga generado correctamente',
            url,
            expiraEnSegundos: URL_EXPIRA_SEGUNDOS
        });
}

// Administrador: puede descargar cualquier reporte activo.
async function obtenerPdfReporte(req, res)
{
    const { id } = req.params;

    if (!/^[1-9]\d*$/.test(id))
    {
        return res.status(400).json({ mensaje: 'ID de reporte inválido' });
    }

    if (!s3)
    {
        return res.status(503).json({ mensaje: 'La descarga de reportes solo está disponible con S3 configurado' });
    }

    try
    {
        const resultado = await pool.query(`SELECT pdf FROM reporte WHERE id = $1 AND estado = TRUE`, [id]);

        return responderDescarga(res, resultado.rows[0]?.pdf);
    }
    catch (error)
    {
        console.error('Error en obtenerPdfReporte:', error);
        return res.status(500).json({ mensaje: 'Error al generar el enlace de descarga' });
    }
}

// Residente: solo puede descargar reportes de una casa que tiene asignada.
async function obtenerPdfReporteResidente(req, res)
{
    const { casaId, reporteId } = req.params;

    if (!/^[1-9]\d*$/.test(casaId) || !/^[1-9]\d*$/.test(reporteId))
    {
        return res.status(400).json({ mensaje: 'Parámetros inválidos' });
    }

    if (!s3)
    {
        return res.status(503).json({ mensaje: 'La descarga de reportes solo está disponible con S3 configurado' });
    }

    try
    {
        const resultado = await pool.query(`SELECT r.pdf
                                            FROM reporte r, reciben rc, tiene t
                                            WHERE r.id = $1
                                            AND rc.reporte_id = r.id
                                            AND rc.casa_id = $2
                                            AND t.casa_id = rc.casa_id
                                            AND t.usuario_id = $3
                                            AND r.estado = TRUE`,
                                            [reporteId, casaId, req.usuario.id] );

        if (resultado.rows.length === 0)
        {
            return res.status(404).json({ mensaje: 'Reporte no encontrado' });
        }

        return responderDescarga(res, resultado.rows[0].pdf);
    }
    catch (error)
    {
        console.error('Error en obtenerPdfReporteResidente:', error);
        return res.status(500).json({ mensaje: 'Error al generar el enlace de descarga' });
    }
}

module.exports = { emitirReporte, obtenerPdfReporte, obtenerPdfReporteResidente };
