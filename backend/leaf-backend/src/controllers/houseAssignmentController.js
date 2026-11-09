const pool = require('../config/db');

async function asociarUsuarioCasa(req, res)
{
    const { id } = req.params;
    const { usuario_id } = req.body;

    if (!/^[1-9]\d*$/.test(id) ||
        !Number.isSafeInteger(usuario_id) ||
        usuario_id <= 0)
    {
        return res.status(400).json(
            {
                mensaje: 'ID de vivienda o usuario inválido'
            });
    }

    try
    {
        const resultado = await pool.query(`INSERT INTO tiene (usuario_id, casa_id, habita)
                                            SELECT u.id, c.id, TRUE
                                            FROM usuarios u, casa c, rol r
                                            WHERE r.id = u.rol_id
                                            AND u.id = $1
                                            AND c.id = $2
                                            AND u.rol_id = 1
                                            AND u.estado = TRUE
                                            AND c.estado = TRUE
                                            AND r.estado = TRUE
                                            ON CONFLICT (usuario_id, casa_id) DO NOTHING
                                            RETURNING usuario_id, casa_id, habita`,
                                            [usuario_id, id] );

        if (resultado.rows.length === 0)
        {
            const asociacion = await pool.query(`SELECT usuario_id
                                                 FROM tiene
                                                 WHERE usuario_id = $1
                                                 AND casa_id = $2`,
                                                 [usuario_id, id] );

            if (asociacion.rows.length > 0)
            {
                return res.status(409).json(
                    {
                        mensaje: 'El usuario ya está asociado con esta vivienda'
                    });
            }

            return res.status(404).json(
                {
                    mensaje: 'Usuario común o vivienda activa no encontrada'
                });
        }

        return res.status(201).json(
            {
                mensaje: 'Usuario asociado correctamente con la vivienda',
                asociacion: resultado.rows[0]
            });
    }
    catch (error)
    {
        console.error('Error en asociarUsuarioCasa:', error);

        return res.status(500).json(
            {
                mensaje: 'Error interno del servidor'
            });
    }
}

async function actualizarHabitante(req, res)
{
    const { id, usuarioId } = req.params;
    const { habita } = req.body;

    if (!/^[1-9]\d*$/.test(id) ||
        !/^[1-9]\d*$/.test(usuarioId))
    {
        return res.status(400).json(
            {
                mensaje: 'ID de vivienda o usuario inválido'
            });
    }

    if (typeof habita !== 'boolean')
    {
        return res.status(400).json(
            {
                mensaje: 'El campo habita debe ser verdadero o falso'
            });
    }

    try
    {
        const resultado = await pool.query(`UPDATE tiene
                                            SET habita = $1
                                            WHERE usuario_id = $2
                                            AND casa_id = $3
                                            RETURNING usuario_id, casa_id, habita`,
                                            [habita, usuarioId, id] );

        if (resultado.rows.length === 0)
        {
            return res.status(404).json(
                {
                    mensaje: 'No existe una asociación entre el usuario y la vivienda'
                });
        }

        return res.json(
            {
                mensaje: 'Estado de residencia actualizado correctamente',
                asociacion: resultado.rows[0]
            });
    }
    catch (error)
    {
        console.error('Error en actualizarHabitante:', error);

        return res.status(500).json(
            {
                mensaje: 'Error interno del servidor'
            });
    }
}

async function obtenerMisCasas(req, res)
{
    try
    {
        const resultado = await pool.query(`SELECT c.id, c.sector, c.numero, c.estado, t.habita
                                            FROM tiene t, casa c, usuarios u, rol r
                                            WHERE c.id = t.casa_id
                                            AND u.id = t.usuario_id
                                            AND r.id = u.rol_id
                                            AND t.usuario_id = $1
                                            AND t.habita = TRUE
                                            AND c.estado = TRUE
                                            AND u.estado = TRUE
                                            AND u.rol_id = 1
                                            AND r.estado = TRUE
                                            ORDER BY c.sector, c.numero`,
                                            [req.usuario.id] );

        return res.json(
            {
                mensaje: 'Viviendas obtenidas correctamente',
                casas: resultado.rows
            });
    }
    catch (error)
    {
        console.error('Error en obtenerMisCasas:', error);

        return res.status(500).json(
            {
                mensaje: 'Error interno del servidor'
            });
    }
}

module.exports = {  asociarUsuarioCasa,
                    actualizarHabitante,
                    obtenerMisCasas };