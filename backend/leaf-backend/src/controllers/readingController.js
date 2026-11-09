const pool = require('../config/db');

function fechaValida(fecha)
{
    if (typeof fecha !== 'string' ||
        !/^\d{4}-\d{2}-\d{2}$/.test(fecha))
    {
        return false;
    }

    const [year, month, day] = fecha.split('-').map(Number);

    const fechaUTC = new Date(Date.UTC(year, month - 1, day));

    return fechaUTC.getUTCFullYear() === year &&
           fechaUTC.getUTCMonth() === month - 1 &&
           fechaUTC.getUTCDate() === day;
}

async function obtenerLecturas(req, res)
{
    const { fecha_inicio, fecha_fin } = req.query;

    if (!fechaValida(fecha_inicio) ||
        !fechaValida(fecha_fin) ||
        fecha_inicio > fecha_fin)
    {
        return res.status(400).json(
            {
                mensaje: 'Debe proporcionar un rango de fechas válido'
            });
    }

    try
    {
        const resultado = await pool.query(`SELECT c.id, c.sector, c.numero,
                                                  
                                                  EXISTS (  SELECT 1
                                                            FROM reciben rc, reporte r, datos d
                                                            WHERE r.id = rc.reporte_id
                                                            AND d.reporte_id = r.id
                                                            AND rc.casa_id = c.id
                                                            AND r.estado = TRUE
                                                            AND d.estado = TRUE
                                                            AND d.fecha >= $1::date
                                                            AND d.fecha < ($2::date + INTERVAL '1 day')
                                                         ) AS lectura_realizada,

                                                  EXISTS (  SELECT 1
                                                            FROM reciben rc, reporte r
                                                            WHERE r.id = rc.reporte_id
                                                            AND rc.casa_id = c.id
                                                            AND r.estado = TRUE
                                                            AND r.fecha >= $1::date
                                                            AND r.fecha < ($2::date + INTERVAL '1 day')
                                                            AND r.pdf IS NOT NULL
                                                            AND TRIM(r.pdf) <> ''
                                                            AND EXISTS (  SELECT 1
                                                                          FROM datos d
                                                                          WHERE d.reporte_id = r.id
                                                                          AND d.estado = TRUE
                                                                          AND d.fecha >= $1::date
                                                                          AND d.fecha < ($2::date + INTERVAL '1 day')
                                                                       )
                                                         ) AS reporte_emitido

                                            FROM casa c
                                            WHERE c.estado = TRUE
                                            ORDER BY c.sector, c.numero`,
                                            [fecha_inicio, fecha_fin] );

        const casas = resultado.rows;

        const completadas = casas.filter(casa => casa.lectura_realizada && casa.reporte_emitido).length;

        const pendientes = casas.filter(casa => !casa.lectura_realizada).length;

        const reportesPendientes = casas.filter(casa => casa.lectura_realizada && !casa.reporte_emitido).length;

        return res.json(
            {
                mensaje: 'Lecturas obtenidas correctamente',
                periodo:
                {
                    fecha_inicio,
                    fecha_fin
                },
                resumen:
                {
                    total_casas: casas.length,
                    completadas,
                    pendientes,
                    reportes_pendientes: reportesPendientes
                },
                casas
            });
    }
    catch (error)
    {
        console.error('Error en obtenerLecturas:', error);

        return res.status(500).json(
            {
                mensaje: 'Error interno del servidor'
            });
    }
}

module.exports = { obtenerLecturas };