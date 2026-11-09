const { S3Client } = require('@aws-sdk/client-s3');
require('dotenv').config();

// Las credenciales vienen del rol de IAM del EC2 (leaf-ec2-role).
// No se necesitan llaves en el código ni en el .env.
const BUCKET = process.env.S3_BUCKET || null;

const s3 = BUCKET
    ? new S3Client({ region: process.env.AWS_REGION || 'us-east-2' })
    : null;

module.exports = { s3, BUCKET };
