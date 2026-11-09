const express = require('express');
const router = express.Router();


const { obtenerLecturas } = require('../controllers/readingController');

const pool = require('../config/db');

const { obtenerPerfil,
        actualizarPerfil,
        registrarMantenimiento } = require('../controllers/adminController');

const { obtenerCasas,
        registrarCasa,
        actualizarCasa,
        cambiarEstadoCasa } = require('../controllers/houseController');

const { obtenerUsuarios,
        actualizarUsuario,
        cambiarEstadoUsuario,
        obtenerUsuariosCasa } = require('../controllers/userManagementController');

const { asociarUsuarioCasa,
        actualizarHabitante } = require('../controllers/houseAssignmentController');

const { requireAuth } = require('../middleware/auth');


const { obtenerNotificacionesAdmin,
        crearNotificacion,
        cambiarEstadoNotificacion } = require('../controllers/notificationController');

const { obtenerReportesAdmin } = require('../controllers/adminReportController');

const { programarLectura } = require('../controllers/scheduleController');

async function requireAdmin(req, res, next)
{
    try
    {
        const resultado = await pool.query( `SELECT u.id
                                             FROM usuarios u, rol r
                                             WHERE r.id = u.rol_id 
                                             AND u.id = $1
                                             AND u.rol_id = 3
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
        console.error('Error en requireAdmin:', error);

        return res.status(500).json(
            {
                mensaje: 'Error interno del servidor'
            });
    }
}

router.use(requireAuth);
router.use(requireAdmin);

router.get('/perfil', obtenerPerfil);

router.put('/perfil', actualizarPerfil);

router.post('/mantenimiento', registrarMantenimiento);

router.get('/casas', obtenerCasas);

router.post('/casas', registrarCasa);

router.put('/casas/:id', actualizarCasa);

router.patch('/casas/:id/estado', cambiarEstadoCasa);

router.get('/lecturas', obtenerLecturas);

router.get('/usuarios', obtenerUsuarios);

router.put('/usuarios/:id', actualizarUsuario);

router.patch('/usuarios/:id/estado', cambiarEstadoUsuario);

router.get('/casas/:id/usuarios', obtenerUsuariosCasa);

router.post('/casas/:id/usuarios', asociarUsuarioCasa);

router.patch('/casas/:id/usuarios/:usuarioId', actualizarHabitante);

router.get('/notificaciones', obtenerNotificacionesAdmin);

router.post('/notificaciones', crearNotificacion);

router.patch('/notificaciones/:id/estado', cambiarEstadoNotificacion);

router.get('/reportes', obtenerReportesAdmin);

router.post('/programaciones', programarLectura);

module.exports = router;