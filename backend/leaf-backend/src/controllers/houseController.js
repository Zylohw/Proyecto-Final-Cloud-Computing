const pool = require('../config/db');

async function obtenerCasas(req, res)
{
    try
    {
        const resultado = await pool.query(`SELECT id, sector, numero, estado
                                            FROM casa
                                            WHERE estado = TRUE
                                            ORDER BY sector, numero`);

        return res.json(
            {
                mensaje: 'Viviendas obtenidas correctamente',
                casas: resultado.rows
            });
    }
    catch (error)
    {
        console.error('Error en obtenerCasas:', error);

        return res.status(500).json(
            {
                mensaje: 'Error interno del servidor'
            });
    }
}

async function registrarCasa(req, res)
{
    const { sector, numero } = req.body;

    if (typeof sector !== 'string' || typeof numero !== 'string' || !sector.trim() || !numero.trim())
    {
        return res.status(400).json(
            {
                mensaje: 'Sector y número son obligatorios'
            });
    }

    if (sector.trim().length > 100 || numero.trim().length > 20)
    {
        return res.status(400).json(
            {
                mensaje: 'Sector o número exceden la longitud permitida'
            });
    }

    try
    {
        const resultado = await pool.query(`INSERT INTO casa (sector, numero)
                                            VALUES ($1, $2)
                                            RETURNING id, sector, numero, estado`,
                                            [sector.trim(), numero.trim()] );

        return res.status(201).json(
            {
                mensaje: 'Vivienda registrada correctamente',
                casa: resultado.rows[0]
            });
    }
    catch (error)
    {
        if (error.code === '23505')
        {
            return res.status(409).json(
                {
                    mensaje: 'Ya existe una vivienda con ese sector y número'
                });
        }

        console.error('Error en registrarCasa:', error);

        return res.status(500).json(
            {
                mensaje: 'Error interno del servidor'
            });
    }
}

async function actualizarCasa(req, res)
{
    const { id } = req.params;
    const { sector, numero } = req.body;

    if (!/^[1-9]\d*$/.test(id))
    {
        return res.status(400).json(
            {
                mensaje: 'ID de vivienda inválido'
            });
    }

    if (typeof sector !== 'string' ||
        typeof numero !== 'string' ||
        !sector.trim() ||
        !numero.trim())
    {
        return res.status(400).json(
            {
                mensaje: 'Sector y número son obligatorios'
            });
    }

    if (sector.trim().length > 100 || numero.trim().length > 20)
    {
        return res.status(400).json(
            {
                mensaje: 'Sector o número exceden la longitud permitida'
            });
    }

    try
    {
        const resultado = await pool.query(`UPDATE casa
                                            SET sector = $1,
                                                numero = $2
                                            WHERE id = $3
                                            RETURNING id, sector, numero, estado`,
                                           [sector.trim(), numero.trim(), id] );

        if (resultado.rows.length === 0)
        {
            return res.status(404).json(
                {
                    mensaje: 'Vivienda no encontrada'
                });
        }

        return res.json(
            {
                mensaje: 'Vivienda actualizada correctamente',
                casa: resultado.rows[0]
            });
    }
    catch (error)
    {
        if (error.code === '23505')
        {
            return res.status(409).json(
                {
                    mensaje: 'Ya existe una vivienda con ese sector y número'
                });
        }

        console.error('Error en actualizarCasa:', error);

        return res.status(500).json(
            {
                mensaje: 'Error interno del servidor'
            });
    }
}

async function cambiarEstadoCasa(req, res)
{
    const { id } = req.params;
    const { estado } = req.body;

    if (!/^[1-9]\d*$/.test(id))
    {
        return res.status(400).json(
            {
                mensaje: 'ID de vivienda inválido'
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
        const resultado = await pool.query(`UPDATE casa
                                            SET estado = $1
                                            WHERE id = $2
                                            RETURNING id, sector, numero, estado`,
                                            [estado, id] );

        if (resultado.rows.length === 0)
        {
            return res.status(404).json(
                {
                    mensaje: 'Vivienda no encontrada'
                });
        }

        return res.json(
            {
                mensaje: 'Estado de vivienda actualizado correctamente',
                casa: resultado.rows[0]
            });
    }
    catch (error)
    {
        console.error('Error en cambiarEstadoCasa:', error);

        return res.status(500).json(
            {
                mensaje: 'Error interno del servidor'
            });
    }
}

module.exports = {  obtenerCasas,
                    registrarCasa,
                    actualizarCasa,
                    cambiarEstadoCasa };