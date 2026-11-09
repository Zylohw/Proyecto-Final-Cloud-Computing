const pool = require('../config/db');

async function obtenerNotificacionesAdmin(req, res)
{
    try
    {
        const resultado = await pool.query(`SELECT n.id, n.descripcion, n.fecha, n.estado,
                                                  n.reporte_id, r.titulo, c.sector, c.numero
                                            FROM notificaciones n, reporte r, reciben rc, casa c
                                            WHERE r.id = n.reporte_id
                                            AND rc.reporte_id = r.id
                                            AND c.id = rc.casa_id
                                            ORDER BY n.fecha DESC, n.id DESC`);

        return res.json(
            {
                mensaje: 'Notificaciones obtenidas correctamente',
                notificaciones: resultado.rows
            });
    }
    catch (error)
    {
        console.error('Error en obtenerNotificacionesAdmin:', error);

        return res.status(500).json(
            {
                mensaje: 'Error interno del servidor'
            });
    }
}

async function crearNotificacion(req, res)
{
    const { descripcion, reporte_id } = req.body;

    if (typeof descripcion !== 'string' || !descripcion.trim() || !Number.isSafeInteger(reporte_id) || reporte_id <= 0)
    {
        return res.status(400).json(
            {
                mensaje: 'Descripción e ID de reporte son obligatorios'
            });
    }

    try
    {
        const resultado = await pool.query(`INSERT INTO notificaciones (descripcion, reporte_id)
                                            SELECT $1, r.id
                                            FROM reporte r
                                            WHERE r.id = $2
                                            AND r.estado = TRUE
                                            RETURNING id, descripcion, fecha, estado, reporte_id`,
                                            [descripcion.trim(), reporte_id] );

        if (resultado.rows.length === 0)
        {
            return res.status(404).json(
                {
                    mensaje: 'Reporte no encontrado o desactivado'
                });
        }

        return res.status(201).json(
            {
                mensaje: 'Notificación creada correctamente',
                notificacion: resultado.rows[0]
            });
    }
    catch (error)
    {
        console.error('Error en crearNotificacion:', error);

        return res.status(500).json(
            {
                mensaje: 'Error interno del servidor'
            });
    }
}

async function cambiarEstadoNotificacion(req, res)
{
    const { id } = req.params;
    const { estado } = req.body;

    if (!/^[1-9]\d*$/.test(id))
    {
        return res.status(400).json(
            {
                mensaje: 'ID de notificación inválido'
            });
    }

    if (typeof estado !== 'boolean')
    {
        return res.status(400).json(
            {
                mensaje: 'El estado debe ser verdadero o falso'
            });
    }

    try
    {
        const resultado = await pool.query(`UPDATE notificaciones
                                            SET estado = $1
                                            WHERE id = $2
                                            RETURNING id, descripcion, fecha, estado, reporte_id`,
                                            [estado, id] );

        if (resultado.rows.length === 0)
        {
            return res.status(404).json(
                {
                    mensaje: 'Notificación no encontrada'
                });
        }

        return res.json(
            {
                mensaje: 'Estado de notificación actualizado correctamente',
                notificacion: resultado.rows[0]
            });
    }
    catch (error)
    {
        console.error('Error en cambiarEstadoNotificacion:', error);

        return res.status(500).json(
            {
                mensaje: 'Error interno del servidor'
            });
    }
}

async function obtenerNotificacionesMantenimiento(req, res)
{
    try
    {
        const resultado = await pool.query(`SELECT n.id, n.descripcion, n.fecha, n.estado,
                                                  n.reporte_id, r.titulo, c.sector, c.numero
                                            FROM notificaciones n, reporte r, reciben rc, casa c
                                            WHERE r.id = n.reporte_id
                                            AND rc.reporte_id = r.id
                                            AND c.id = rc.casa_id
                                            AND r.usuario_id = $1
                                            AND r.estado = TRUE
                                            AND n.estado = TRUE
                                            ORDER BY n.fecha DESC, n.id DESC`,
                                            [req.usuario.id] );

        return res.json(
            {
                mensaje: 'Notificaciones obtenidas correctamente',
                notificaciones: resultado.rows
            });
    }
    catch (error)
    {
        console.error('Error en obtenerNotificacionesMantenimiento:', error);

        return res.status(500).json(
            {
                mensaje: 'Error interno del servidor'
            });
    }
}

async function obtenerNotificacionesUsuario(req, res)
{
    try
    {
        const resultado = await pool.query(`SELECT n.id, n.descripcion, n.fecha, n.estado,
                                                  n.reporte_id, r.titulo
                                            FROM notificaciones n, reporte r
                                            WHERE r.id = n.reporte_id
                                            AND n.estado = TRUE
                                            AND r.estado = TRUE
                                            AND EXISTS (  SELECT 1
                                                         FROM reciben rc, casa c, tiene t
                                                         WHERE c.id = rc.casa_id
                                                         AND t.casa_id = c.id
                                                         AND rc.reporte_id = r.id
                                                         AND t.usuario_id = $1
                                                         AND t.habita = TRUE
                                                         AND c.estado = TRUE
                                                      )
                                            ORDER BY n.fecha DESC, n.id DESC`,
                                            [req.usuario.id] );

        return res.json(
            {
                mensaje: 'Notificaciones obtenidas correctamente',
                notificaciones: resultado.rows
            });
    }
    catch (error)
    {
        console.error('Error en obtenerNotificacionesUsuario:', error);

        return res.status(500).json(
            {
                mensaje: 'Error interno del servidor'
            });
    }
}

module.exports = {  obtenerNotificacionesAdmin,
                    crearNotificacion,
                    cambiarEstadoNotificacion,
                    obtenerNotificacionesMantenimiento,
                    obtenerNotificacionesUsuario };