-- Ejecuta esto una vez, despues de correr tu Script_de_La_Base_de_Datos.sql
-- Inserta los 3 roles que usa el backend.

INSERT INTO rol (nombre) VALUES
  ('Administrador'),
  ('Mantenimiento'),
  ('Comun')
ON CONFLICT (nombre) DO NOTHING;
