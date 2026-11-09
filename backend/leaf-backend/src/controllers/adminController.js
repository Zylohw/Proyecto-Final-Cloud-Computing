const bcrypt = require('bcrypt');
const pool = require('../config/db');

const SALT_ROUNDS = 10;
const ROL_MANTENIMIENTO = 2;

async function obtenerPerfil(req, res)
{
    try
    {
        const resultado = await pool.query(`SELECT id, nombre, correo, estado
                                            FROM usuarios
                                            WHERE id = $1
                                            AND rol_id = 3
                                            AND estado = TRUE`,
                                            [req.usuario.id] );

        if (resultado.rows.length === 0)
        {
            return res.status(404).json(
                {
                    mensaje: 'Administrador no encontrado'
                });
        }

        return res.json(
            {
                usuario: resultado.rows[0]
            });
    }
    catch (error)
    {
        console.error('Error en obtenerPerfil:', error);

        return res.status(500).json(
            {
                mensaje: 'Error interno del servidor'
            });
    }
}

async function actualizarPerfil(req, res)
{
    const { nombre, correo, contrasena } = req.body;

    if (typeof nombre !== 'string' ||
        typeof correo !== 'string' ||
        !nombre.trim() ||
        !correo.trim())
    {
        return res.status(400).json(
            {
                mensaje: 'Nombre y correo son obligatorios'
            });
    }

    if (contrasena !== undefined &&
        (typeof contrasena !== 'string' || contrasena.length < 6))
    {
        return res.status(400).json(
            {
                mensaje: 'La contraseña debe tener al menos 6 caracteres'
            });
    }

    try
    {
        let hash = null;

        if (contrasena)
        {
            hash = await bcrypt.hash(contrasena, SALT_ROUNDS);
        }

        const resultado = await pool.query(`UPDATE usuarios
                                            SET nombre = $1,
                                                correo = $2,
                                                contrasena = COALESCE($3, contrasena)
                                            WHERE id = $4
                                            AND rol_id = 3
                                            AND estado = TRUE
                                            RETURNING id, nombre, correo, estado`,
                                            [nombre.trim(), correo.trim(), hash, req.usuario.id] );

        if (resultado.rows.length === 0)
        {
            return res.status(404).json(
                {
                    mensaje: 'Administrador no encontrado'
                });
        }

        return res.json(
            {
                mensaje: 'Perfil actualizado correctamente',
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

        console.error('Error en actualizarPerfil:', error);

        return res.status(500).json(
            {
                mensaje: 'Error interno del servidor'
            });
    }
}

async function registrarMantenimiento(req, res)
{
    const { nombre, correo, contrasena } = req.body;

    if (typeof nombre !== 'string' ||
        typeof correo !== 'string' ||
        typeof contrasena !== 'string' ||
        !nombre.trim() ||
        !correo.trim())
    {
        return res.status(400).json(
            {
                mensaje: 'Nombre, correo y contraseña son obligatorios'
            });
    }

    if (contrasena.length < 6)
    {
        return res.status(400).json(
            {
                mensaje: 'La contraseña debe tener al menos 6 caracteres'
            });
    }

    try
    {
        const hash = await bcrypt.hash(contrasena, SALT_ROUNDS);

        const resultado = await pool.query(`INSERT INTO usuarios (nombre, correo, contrasena, rol_id)
                                            VALUES ($1, $2, $3, $4)
                                            RETURNING id, nombre, correo, estado, rol_id`,
                                            [nombre.trim(), correo.trim(), hash, ROL_MANTENIMIENTO] );

        return res.status(201).json(
            {
                mensaje: 'Usuario de mantenimiento registrado correctamente',
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

        if (error.code === '23503')
        {
            return res.status(500).json(
                {
                    mensaje: 'El rol de mantenimiento no existe'
                });
        }

        console.error('Error en registrarMantenimiento:', error);

        return res.status(500).json(
            {
                mensaje: 'Error interno del servidor'
            });
    }
}

module.exports = {  obtenerPerfil,
                    actualizarPerfil,
                    registrarMantenimiento };