const pool = require('../config/db');

async function obtenerHistorialConsumo(req, res)
{
    const { id } = req.params;

    const meses = req.query.meses === undefined ? 6 : Number(req.query.meses);

    if (!/^[1-9]\d*$/.test(id))
    {
        return res.status(400).json(
            {
                mensaje: 'ID de vivienda inválido'
            });
    }

    if (!Number.isInteger(meses) || meses < 1 || meses > 12)
    {
        return res.status(400).json(
            {
                mensaje: 'El período debe estar entre 1 y 12 meses'
            });
    }

    try
    {
        const vivienda = await pool.query(`SELECT c.id, c.sector, c.numero
                                           FROM casa c, tiene t
                                           WHERE t.casa_id = c.id
                                           AND c.id = $1
                                           AND t.usuario_id = $2
                                           AND t.habita = TRUE
                                           AND c.estado = TRUE`,
                                           [id, req.usuario.id] );

        if (vivienda.rows.length === 0)
        {
            return res.status(404).json(
                {
                    mensaje: 'Vivienda no encontrada o no asociada al usuario'
                });
        }

        const resultado = await pool.query(`WITH meses AS
                                            (
                                                SELECT (DATE_TRUNC('month', NOW() AT TIME ZONE 'America/Guatemala') - (n * INTERVAL '1 month'))::date AS mes_inicio, n
                                                FROM GENERATE_SERIES($2::integer, 0, -1) AS n
                                            ),

                                            lecturas AS
                                            (
                                                SELECT DISTINCT ON (DATE_TRUNC('month', d.fecha))
                                                      DATE_TRUNC('month', d.fecha)::date AS mes_inicio,
                                                      d.id, d.medida_tomada, d.fecha
                                                FROM datos d, reporte r, reciben rc
                                                WHERE r.id = d.reporte_id
                                                AND rc.reporte_id = r.id
                                                AND rc.casa_id = $1
                                                AND d.estado = TRUE
                                                AND r.estado = TRUE
                                                ORDER BY DATE_TRUNC('month', d.fecha),
                                                        d.fecha DESC, d.id DESC
                                            ),

                                            historial AS
                                            (
                                                SELECT m.mes_inicio, m.n,

                                                      ( SELECT l.medida_tomada
                                                        FROM lecturas l
                                                        WHERE l.mes_inicio = m.mes_inicio ) AS medida_tomada,

                                                      ( SELECT l.fecha
                                                        FROM lecturas l
                                                        WHERE l.mes_inicio = m.mes_inicio ) AS fecha

                                                FROM meses m
                                            ),

                                            historial_consumo AS
                                            (
                                                SELECT h.mes_inicio, h.n, h.medida_tomada, h.fecha,
                                                       LAG(h.medida_tomada) OVER (ORDER BY h.mes_inicio) AS lectura_anterior
                                                FROM historial h
                                            )
                                            
                                            SELECT TO_CHAR(mes_inicio, 'YYYY-MM') AS periodo,
                                                   EXTRACT(YEAR FROM mes_inicio) :: integer AS anio,
                                                   EXTRACT(MONTH FROM mes_inicio) :: integer AS mes,
                                                   medida_tomada AS lectura,
                                                   lectura_anterior,
                                                   CASE
                                                       WHEN medida_tomada IS NOT NULL
                                                       AND lectura_anterior IS NOT NULL
                                                       AND medida_tomada >= lectura_anterior
                                                       THEN medida_tomada - lectura_anterior
                                                       ELSE NULL
                                                   END AS consumo,
                                                   fecha
                                            FROM historial_consumo
                                            WHERE n < $2
                                            ORDER BY mes_inicio`,
                                            [id, meses] );

        const nombresMeses = [ 'Enero', 'Febrero', 'Marzo', 'Abril',
                               'Mayo', 'Junio', 'Julio', 'Agosto',
                               'Septiembre', 'Octubre', 'Noviembre', 'Diciembre' ];

        const historial = resultado.rows.map((fila) =>
            {
                let estado = 'Calculado';

                if (fila.lectura === null)
                {
                    estado = 'Sin lectura';
                }
                else if (fila.lectura_anterior === null)
                {
                    estado = 'Sin lectura anterior';
                }
                else if (fila.consumo === null)
                {
                    estado = 'Lectura inconsistente';
                }

                return {
                    periodo: fila.periodo,
                    mes: nombresMeses[fila.mes - 1],
                    anio: fila.anio,
                    lectura: fila.lectura === null ? null : Number(fila.lectura),
                    lectura_anterior: fila.lectura_anterior === null ? null : Number(fila.lectura_anterior),
                    consumo: fila.consumo === null ? null : Number(fila.consumo),
                    fecha: fila.fecha,
                    estado
                };
            });

        return res.json(
            {
                mensaje: 'Historial obtenido correctamente',
                casa: vivienda.rows[0],
                periodo:
                {
                    meses
                },
                historial
            });
    }
    catch (error)
    {
        console.error('Error en obtenerHistorialConsumo:', error);

        return res.status(500).json(
            {
                mensaje: 'Error interno del servidor'
            });
    }
}

module.exports = { obtenerHistorialConsumo };