const express = require('express');
const router = express.Router();
const { emitirReporte } = require('../controllers/reportController');

const pool = require('../config/db');

const { obtenerCasasMantenimiento,
        registrarLectura,
        obtenerReportesMantenimiento } = require('../controllers/maintenanceController');

const { requireAuth } = require('../middleware/auth');

const { obtenerNotificacionesMantenimiento } = require('../controllers/notificationController');

async function requireMaintenance(req, res, next)
{
    try
    {
        const resultado = await pool.query( `SELECT u.id
                                             FROM usuarios u, rol r
                                             WHERE r.id = u.rol_id 
                                             AND u.id = $1
                                             AND u.rol_id = 2
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
        console.error('Error en requireMaintenance:', error);

        return res.status(500).json(
            {
                mensaje: 'Error interno del servidor'
            });
    }
}

router.use(requireAuth);
router.use(requireMaintenance);

router.get('/casas', obtenerCasasMantenimiento);

router.post('/lecturas', registrarLectura);

router.get('/reportes', obtenerReportesMantenimiento);

router.post('/reportes/:id/emitir', emitirReporte);

router.get('/notificaciones', obtenerNotificacionesMantenimiento);

module.exports = router;