const bcrypt = require('bcrypt');
const pool = require('../config/db');
const { generarToken } = require('../utils/jwt');

const SALT_ROUNDS = 10;

async function login(req, res)
{
    const { correo, contrasena } = req.body;

    if (!correo || !contrasena)
    {
        return res.status(400).json(
            {
                mensaje: 'Correo y contrasena son obligatorios'
            });
    }

    try
    {
        const resultado = await pool.query(`SELECT u.id, u.nombre, u.correo, u.contrasena,
                                                   u.estado, r.nombre AS rol
                                            FROM usuarios u, rol r
                                            WHERE r.id = u.rol_id
                                            AND u.correo = $1`,
                                            [correo] );

        if (resultado.rows.length === 0)
        {
            return res.status(401).json(
                {
                    mensaje: 'Credenciales invalidas'
                });
        }

        const usuario = resultado.rows[0];

        if (!usuario.estado)
        {
            return res.status(403).json(
                {
                    mensaje: 'El usuario esta deshabilitado'
                });
        }

        const coincide = await bcrypt.compare(contrasena, usuario.contrasena);

        if (!coincide)
        {
            return res.status(401).json(
                {
                    mensaje: 'Credenciales invalidas'
                });
        }

        const token = generarToken(
            {
                id: usuario.id,
                correo: usuario.correo,
                rol: usuario.rol
            });

        return res.json(
            {
                mensaje: 'Login exitoso',
                token,
                usuario:
                {
                    id: usuario.id,
                    nombre: usuario.nombre,
                    correo: usuario.correo,
                    rol: usuario.rol
                }
            });
    }
    catch (error)
    {
        console.error('Error en login:', error);

        return res.status(500).json(
            {
                mensaje: 'Error interno del servidor'
            });
    }
}

async function resetPassword(req, res)
{
    const { correo, nuevaContrasena } = req.body;

    if (!correo || !nuevaContrasena)
    {
        return res.status(400).json(
            {
                mensaje: 'Correo y nueva contrasena son obligatorios'
            });
    }

    if (nuevaContrasena.length < 6)
    {
        return res.status(400).json(
            {
                mensaje: 'La nueva contrasena debe tener al menos 6 caracteres'
            });
    }

    try
    {
        const existe = await pool.query(`SELECT id
                                         FROM usuarios
                                         WHERE correo = $1`,
                                         [correo] );

        if (existe.rows.length === 0)
        {
            return res.status(404).json(
                {
                    mensaje: 'No existe un usuario con ese correo'
                });
        }

        const hash = await bcrypt.hash(nuevaContrasena, SALT_ROUNDS);

        await pool.query(`UPDATE usuarios
                          SET contrasena = $1
                          WHERE correo = $2`,
                          [hash, correo] );

        return res.json(
            {
                mensaje: 'Contrasena actualizada correctamente'
            });
    }
    catch (error)
    {
        console.error('Error en resetPassword:', error);

        return res.status(500).json(
            {
                mensaje: 'Error interno del servidor'
            });
    }
}

module.exports = { login, resetPassword };