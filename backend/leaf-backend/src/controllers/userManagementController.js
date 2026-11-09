const pool = require('../config/db');

async function obtenerUsuarios(req, res)
{
    try
    {
        const resultado = await pool.query(`SELECT u.id, u.nombre, u.correo, u.estado,
                                                  u.rol_id, r.nombre AS rol
                                            FROM usuarios u, rol r
                                            WHERE r.id = u.rol_id
                                            AND u.rol_id IN (1, 2)
                                            ORDER BY u.id`);

        return res.json(
            {
                mensaje: 'Usuarios obtenidos correctamente',
                usuarios: resultado.rows
            });
    }
    catch (error)
    {
        console.error('Error en obtenerUsuarios:', error);

        return res.status(500).json(
            {
                mensaje: 'Error interno del servidor'
            });
    }
}

async function actualizarUsuario(req, res)
{
    const { id } = req.params;
    const { nombre, correo } = req.body;

    if (!/^[1-9]\d*$/.test(id))
    {
        return res.status(400).json(
            {
                mensaje: 'ID de usuario inválido'
            });
    }

    if (typeof nombre !== 'string' || typeof correo !== 'string' || !nombre.trim() || !correo.trim())
    {
        return res.status(400).json(
            {
                mensaje: 'Nombre y correo son obligatorios'
            });
    }

    if (nombre.trim().length > 150 ||
        correo.trim().length > 150)
    {
        return res.status(400).json(
            {
                mensaje: 'Nombre o correo exceden la longitud permitida'
            });
    }

    try
    {
        const resultado = await pool.query(`UPDATE usuarios
                                            SET nombre = $1,
                                               correo = $2
                                            WHERE id = $3
                                            AND rol_id IN (1, 2)
                                            RETURNING id, nombre, correo, estado, rol_id`,
                                            [nombre.trim(), correo.trim(), id] );

        if (resultado.rows.length === 0)
        {
            return res.status(404).json(
                {
                    mensaje: 'Usuario no encontrado'
                });
        }

        return res.json(
            {
                mensaje: 'Usuario actualizado correctamente',
                usuario: resultado.rows[0]
            });
    }
    catch (error)
    {
        if (error.code === '23505')
        {
            return res.status(409).json(
                {
                    mensaje: 'Ya existe un usuario con ese correo'
                });
        }

        console.error('Error en actualizarUsuario:', error);

        return res.status(500).json(
            {
                mensaje: 'Error interno del servidor'
            });
    }
}

async function cambiarEstadoUsuario(req, res)
{
    const { id } = req.params;
    const { estado } = req.body;

    if (!/^[1-9]\d*$/.test(id))
    {
        return res.status(400).json(
            {
                mensaje: 'ID de usuario inválido'
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
        const resultado = await pool.query(`UPDATE usuarios
                                            SET estado = $1
                                            WHERE id = $2
                                            AND rol_id IN (1, 2)
                                            RETURNING id, nombre, correo, estado, rol_id`,
                                            [estado, id] );

        if (resultado.rows.length === 0)
        {
            return res.status(404).json(
                {
                    mensaje: 'Usuario no encontrado'
                });
        }

        return res.json(
            {
                mensaje: 'Estado del usuario actualizado correctamente',
                usuario: resultado.rows[0]
            });
    }
    catch (error)
    {
        console.error('Error en cambiarEstadoUsuario:', error);

        return res.status(500).json(
            {
                mensaje: 'Error interno del servidor'
            });
    }
}

async function obtenerUsuariosCasa(req, res)
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
        const vivienda = await pool.query(`SELECT id, sector, numero, estado
                                           FROM casa
                                           WHERE id = $1`,
                                           [id] );

        if (vivienda.rows.length === 0)
        {
            return res.status(404).json(
                {
                    mensaje: 'Vivienda no encontrada'
                });
        }

        const resultado = await pool.query(`SELECT u.id, u.nombre, u.correo, u.estado,
                                                  t.habita
                                            FROM tiene t, usuarios u
                                            WHERE u.id = t.usuario_id
                                            AND t.casa_id = $1
                                            ORDER BY u.nombre`,
                                            [id] );

        return res.json(
            {
                mensaje: 'Usuarios de la vivienda obtenidos correctamente',
                casa: vivienda.rows[0],
                usuarios: resultado.rows
            });
    }
    catch (error)
    {
        console.error('Error en obtenerUsuariosCasa:', error);

        return res.status(500).json(
            {
                mensaje: 'Error interno del servidor'
            });
    }
}

module.exports = {  obtenerUsuarios,
                    actualizarUsuario,
                    cambiarEstadoUsuario,
                    obtenerUsuariosCasa };