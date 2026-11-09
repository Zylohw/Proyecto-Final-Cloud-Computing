const pool = require('../config/db');

async function obtenerReportesAdmin(req, res)
{
    try
    {
        const resultado = await pool.query(`SELECT r.id, r.titulo, r.descripcion, r.fecha, r.pdf, r.estado,
                                                   c.id AS casa_id, c.sector, c.numero,
                                                   u.id AS mantenimiento_id, u.nombre AS mantenimiento
                                            FROM reporte r, reciben rc, casa c, usuarios u
                                            WHERE rc.reporte_id = r.id
                                            AND c.id = rc.casa_id
                                            AND u.id = r.usuario_id
                                            AND r.estado = TRUE
                                            AND c.estado = TRUE
                                            AND u.rol_id = 2
                                            AND u.estado = TRUE
                                            ORDER BY r.fecha DESC, r.id DESC`);

        return res.json(
            {
                mensaje: 'Reportes obtenidos correctamente',
                reportes: resultado.rows
            });
    }
    catch (error)
    {
        console.error('Error en obtenerReportesAdmin:', error);

        return res.status(500).json(
            {
                mensaje: 'Error interno del servidor'
            });
    }
}

module.exports = { obtenerReportesAdmin };