const pool = require('../config/db');

function fechaValida(fecha)
{
    if (typeof fecha !== 'string' || !/^\d{4}-\d{2}-\d{2}$/.test(fecha))
    {
        return false;
    }

    const [year, month, day] = fecha.split('-').map(Number);

    const fechaUTC = new Date(Date.UTC(year, month - 1, day));

    return fechaUTC.getUTCFullYear() === year &&
           fechaUTC.getUTCMonth() === month - 1 &&
           fechaUTC.getUTCDate() === day;
}

async function programarLectura(req, res)
{
    const { reporte_id, fecha_lectura, indicaciones } = req.body;

    if (!Number.isSafeInteger(reporte_id) || reporte_id <= 0)
    {
        return res.status(400).json(
            {
                mensaje: 'ID de reporte inválido'
            });
    }

    if (!fechaValida(fecha_lectura))
    {
        return res.status(400).json(
            {
                mensaje: 'Fecha de lectura inválida'
            });
    }

    if (indicaciones !== undefined &&
        typeof indicaciones !== 'string')
    {
        return res.status(400).json(
            {
                mensaje: 'Las indicaciones no son válidas'
            });
    }

    try
    {
        const reporte = await pool.query(`SELECT r.id, c.sector, c.numero,
                                                u.nombre AS mantenimiento
                                          FROM reporte r, reciben rc, casa c, usuarios u
                                          WHERE rc.reporte_id = r.id
                                          AND c.id = rc.casa_id
                                          AND u.id = r.usuario_id
                                          AND r.id = $1
                                          AND r.estado = TRUE
                                          AND c.estado = TRUE
                                          AND u.rol_id = 2
                                          AND u.estado = TRUE`,
                                          [reporte_id] );

        if (reporte.rows.length === 0)
        {
            return res.status(404).json(
                {
                    mensaje: 'Reporte no encontrado o no disponible'
                });
        }

        const datos = reporte.rows[0];

        const descripcion = `Lectura programada para ${fecha_lectura}. ` +
                            `Sector: ${datos.sector}. ` +
                            `Vivienda: ${datos.numero}. ` +
                            `Indicaciones: ${indicaciones?.trim() || 'Sin indicaciones adicionales'}`;

        const resultado = await pool.query(`INSERT INTO notificaciones (descripcion, reporte_id)
                                            VALUES ($1, $2)
                                            RETURNING id, descripcion, fecha, estado, reporte_id`,
                                            [descripcion, reporte_id] );

        return res.status(201).json(
            {
                mensaje: 'Lectura programada correctamente',
                mantenimiento: datos.mantenimiento,
                notificacion: resultado.rows[0]
            });
    }
    catch (error)
    {
        console.error('Error en programarLectura:', error);

        return res.status(500).json(
            {
                mensaje: 'Error interno del servidor'
            });
    }
}

module.exports = { programarLectura };
