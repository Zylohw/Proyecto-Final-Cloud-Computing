const bcrypt = require('bcrypt');
const pool = require('../config/db');

const SALT_ROUNDS = 10;
const ROL_POR_DEFECTO = 'Comun';

async function registrarUsuario(req, res)
{
    const { nombre, correo, contrasena } = req.body;

    if (!nombre || !correo || !contrasena)
    {
        return res.status(400).json(
            {
                mensaje: 'Nombre, correo y contrasena son obligatorios'
            });
    }

    if (contrasena.length < 6)
    {
        return res.status(400).json(
            {
                mensaje: 'La contrasena debe tener al menos 6 caracteres'
            });
    }

    const cliente = await pool.connect();

    try
    {
        const correoExistente = await cliente.query(`SELECT id
                                                     FROM usuarios
                                                     WHERE correo = $1`,
                                                     [correo] );

        if (correoExistente.rows.length > 0)
        {
            return res.status(409).json(
                {
                    mensaje: 'Ya existe un usuario con ese correo'
                });
        }

        const rolResultado = await cliente.query(`SELECT id
                                                  FROM rol
                                                  WHERE nombre = $1`,
                                                  [ROL_POR_DEFECTO] );

        if (rolResultado.rows.length === 0)
        {
            return res.status(500).json(
                {
                    mensaje: `El rol "${ROL_POR_DEFECTO}" no existe en la tabla rol. Debe crearse primero.`
                });
        }

        const rolId = rolResultado.rows[0].id;
        const hash = await bcrypt.hash(contrasena, SALT_ROUNDS);

        const nuevoUsuario = await cliente.query(`INSERT INTO usuarios (nombre, correo, contrasena, rol_id)
                                                  VALUES ($1, $2, $3, $4)
                                                  RETURNING id, nombre, correo, estado`,
                                                  [nombre, correo, hash, rolId] );

        return res.status(201).json(
            {
                mensaje: 'Usuario registrado correctamente',
                usuario: nuevoUsuario.rows[0]
            });
    }
    catch (error)
    {
        console.error('Error en registrarUsuario:', error);

        return res.status(500).json(
            {
                mensaje: 'Error interno del servidor'
            });
    }
    finally
    {
        cliente.release();
    }
}

module.exports = { registrarUsuario };
