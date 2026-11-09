const pool = require('../config/db');

const fs = require('fs/promises');
const path = require('path');

const REPORTES_DIR = path.join(__dirname, '../../private/reportes');

async function obtenerReportesUsuario(req, res)
{
    const { id } = req.params;

    if (!/^[1-9]\d*$/.test(id))
    {
        return res.status(400).json(
            {
                mensaje: 'ID de vivienda inválido'
            });
    }

    try
    {
        const vivienda = await pool.query( `SELECT c.id, c.sector, c.numero
                                            FROM casa c, tiene t
                                            WHERE t.casa_id = c.id
                                            AND c.id = $1
                                            AND t.usuario_id = $2
                                            AND t.habita = TRUE
                                            AND c.estado = TRUE`,
                                            [id, req.usuario.id] );

        if (vivienda.rows.length === 0)
        {
            return res.status(404).json(
                {
                    mensaje: 'Vivienda no encontrada o no asociada al usuario'
                });
        }

        const resultado = await pool.query( `SELECT r.id, r.titulo, r.descripcion, r.fecha, r.pdf,
                                                    rc.recibido,
                                                    d.medida_tomada, d.fecha AS fecha_lectura, d.contenido
                                             FROM reporte r, reciben rc, datos d
                                             WHERE rc.reporte_id = r.id
                                             AND rc.casa_id = $1
                                             AND d.reporte_id = r.id
                                             AND d.estado = TRUE
                                             AND d.id = (   SELECT d2.id
                                                            FROM datos d2
                                                            WHERE d2.reporte_id = r.id
                                                            AND d2.estado = TRUE
                                                            ORDER BY d2.fecha DESC, d2.id DESC
                                                            LIMIT 1 )
                                             AND r.estado = TRUE
                                             AND r.pdf IS NOT NULL
                                             AND TRIM(r.pdf) <> ''
                                             ORDER BY r.fecha DESC, r.id DESC`,
                                             [id] );

        return res.json(
            {
                mensaje: 'Reportes obtenidos correctamente',
                casa: vivienda.rows[0],
                reportes: resultado.rows
            });
    }
    catch (error)
    {
        console.error('Error en obtenerReportesUsuario:', error);

        return res.status(500).json(
            {
                mensaje: 'Error interno del servidor'
            });
    }
}

async function descargarReporteUsuario(req, res)
{
    const { id } = req.params;

    if (!/^[1-9]\d*$/.test(id))
    {
        return res.status(400).json(
            {
                mensaje: 'ID de reporte inválido'
            });
    }

    try
    {
        const resultado = await pool.query(`SELECT DISTINCT r.id, r.titulo, r.pdf
                                            FROM reporte r, reciben rc, casa c, tiene t
                                            WHERE rc.reporte_id = r.id
                                            AND t.casa_id = c.id
                                            AND c.id = rc.casa_id
                                            AND r.id = $1
                                            AND t.usuario_id = $2
                                            AND t.habita = TRUE
                                            AND c.estado = TRUE
                                            AND r.estado = TRUE
                                            AND r.pdf IS NOT NULL
                                            AND TRIM(r.pdf) <> ''`,
                                            [id, req.usuario.id] );

        if (resultado.rows.length === 0)
        {
            return res.status(404).json(
                {
                    mensaje: 'Reporte no encontrado o sin permisos de acceso'
                });
        }

        const reporte = resultado.rows[0];

        if (!/^reporte-[1-9]\d*\.pdf$/.test(reporte.pdf))
        {
            return res.status(404).json(
                {
                    mensaje: 'Archivo PDF no disponible'
                });
        }

        const rutaArchivo = path.join(REPORTES_DIR, reporte.pdf);

        try
        {
            await fs.access(rutaArchivo);
        }
        catch (error)
        {
            return res.status(404).json(
                {
                    mensaje: 'El archivo PDF no existe en el servidor'
                });
        }

        return res.download( rutaArchivo, reporte.pdf, (error) =>
            {
                if (error && !res.headersSent)
                {
                    console.error('Error al descargar reporte:', error);

                    return res.status(500).json(
                        {
                            mensaje: 'Error al descargar el reporte'
                        });
                }
            }
        );
    }
    catch (error)
    {
        console.error('Error en descargarReporteUsuario:', error);

        return res.status(500).json(
            {
                mensaje: 'Error interno del servidor'
            });
    }
}

async function confirmarRecepcionReporte(req, res)
{
    const { casaId, reporteId } = req.params;

    if (!/^[1-9]\d*$/.test(casaId) || !/^[1-9]\d*$/.test(reporteId))
    {
        return res.status(400).json(
            {
                mensaje: 'ID de vivienda o reporte inválido'
            });
    }

    try
    {
        const resultado = await pool.query(`UPDATE reciben rc
                                            SET recibido = TRUE
                                            FROM reporte r, casa c, tiene t
                                            WHERE rc.reporte_id = r.id
                                            AND rc.casa_id = c.id
                                            AND t.casa_id = c.id
                                            AND rc.casa_id = $1
                                            AND rc.reporte_id = $2
                                            AND t.usuario_id = $3
                                            AND t.habita = TRUE
                                            AND c.estado = TRUE
                                            AND r.estado = TRUE
                                            AND r.pdf IS NOT NULL
                                            AND TRIM(r.pdf) <> ''
                                            RETURNING
                                                rc.casa_id,
                                                rc.reporte_id,
                                                rc.recibido`,
                                            [casaId, reporteId, req.usuario.id] );

        if (resultado.rows.length === 0)
        {
            return res.status(404).json(
                {
                    mensaje: 'Reporte no encontrado o sin permisos de acceso'
                });
        }

        return res.json(
            {
                mensaje: 'Recepción del reporte confirmada correctamente',
                reporte: resultado.rows[0]
            });
    }
    catch (error)
    {
        console.error('Error en confirmarRecepcionReporte:', error);

        return res.status(500).json(
            {
                mensaje: 'Error interno del servidor'
            });
    }

}

module.exports = {  obtenerReportesUsuario,
                    descargarReporteUsuario,
                    confirmarRecepcionReporte };