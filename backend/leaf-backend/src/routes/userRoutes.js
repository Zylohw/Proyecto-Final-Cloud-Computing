const express = require('express');
const router = express.Router();

const { obtenerPdfReporteResidente } = require('../controllers/reportController');

const pool = require('../config/db');

const { registrarUsuario } = require('../controllers/userController');

const { obtenerMisCasas } = require('../controllers/houseAssignmentController');

const { obtenerReportesUsuario,
        descargarReporteUsuario,
        confirmarRecepcionReporte } = require('../controllers/userReportController');

const { obtenerHistorialConsumo } = require('../controllers/consumptionController');

const { requireAuth } = require('../middleware/auth');

const { obtenerNotificacionesUsuario } = require('../controllers/notificationController');

async function requireCommon(req, res, next)
{
    try
    {
        const resultado = await pool.query( `SELECT u.id
                                             FROM usuarios u, rol r
                                             WHERE r.id = u.rol_id 
                                             AND u.id = $1
                                             AND u.rol_id = 1
                                             AND u.estado = TRUE
                                             AND r.estado = TRUE`,
                                            [req.usuario.id] );

        if (resultado.rows.length === 0)
        {
            return res.status(403).json(
                {
                    mensaje: 'No tienes permisos para esta acción'
                });
        }

        next();
    }
    catch (error)
    {
        console.error('Error en requireCommon:', error);

        return res.status(500).json(
            {
                mensaje: 'Error interno del servidor'
            });
    }
}

router.post('/registro', registrarUsuario);

router.get( '/mis-casas',
            requireAuth,
            requireCommon,
            obtenerMisCasas );

router.get( '/casas/:id/reportes',
            requireAuth,
            requireCommon,
            obtenerReportesUsuario );

router.get( '/reportes/:id/descargar',
            requireAuth,
            requireCommon,
            descargarReporteUsuario );


router.patch( '/casas/:casaId/reportes/:reporteId/recibido',
              requireAuth,
              requireCommon,
              confirmarRecepcionReporte );

router.get( '/casas/:id/historial',
            requireAuth,
            requireCommon,
            obtenerHistorialConsumo );


router.get( '/notificaciones',
            requireAuth,
            requireCommon,
            obtenerNotificacionesUsuario );

router.get( '/casas/:casaId/reportes/:reporteId/pdf',
            requireAuth,
            requireCommon,
            obtenerPdfReporteResidente );


module.exports = router;
