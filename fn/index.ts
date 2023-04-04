import axios from 'axios';
import * as dotenv from 'dotenv';
import * as fs from 'fs/promises';
import AdmZip from 'adm-zip';
import path from 'path';
import { S3Client, PutObjectCommand, PutObjectCommandInput } from '@aws-sdk/client-s3';
dotenv.config();

const API_KEY = process.env.API_KEY;
const CERTIFICATE_ID = process.env.CERTIFICATE_ID;
const URL = process.env.URL;

const client = new S3Client({ region: process.env.REGION });

interface DownloadCertificateApiResponse {
  // Define the structure of the response data here
  'certificate.crt': string;
  'ca_bundle.crt': string;
}

const uploadToS3 = async (key: string, file: string): Promise<void> => {
  const fileContent = await fs.readFile(file);
  const params: PutObjectCommandInput = {
    Bucket: process.env.BUCKET_NAME,
    Key: key,
    Body: fileContent,
  };
  const command = new PutObjectCommand(params);
  await client.send(command);
};

const zipFile = async (sourcePath: string, destPath: string): Promise<void> => {
  return new Promise((resolve, reject) => {
    try {
      const zip = new AdmZip();
      zip.addLocalFolder(sourcePath);
      zip.writeZip(destPath);
      resolve();
    } catch (error) {
      reject(error);
    }
  });
};

const writeToFile = async (fileName: string, data: string): Promise<void> => {
  try {
    await fs.writeFile(`tmp/${fileName}`, data);
  } catch (error) {
    console.error(error);
    throw error;
  }
};

const downloadCertificate = async (): Promise<DownloadCertificateApiResponse> => {
  try {
    const response = await axios.get<DownloadCertificateApiResponse>(
      `${URL}/certificates/${CERTIFICATE_ID}/download/return?access_key=${API_KEY}`,
    );
    return response.data;
  } catch (error) {
    console.error(error);
    throw error;
  }
};

const cleanUpTmpDirectory = async (): Promise<void> => {
  const tempDir = './tmp';
  try {
    const files = await fs.readdir(tempDir);

    const fileDeletionPromises = files
      .filter((file) => file.endsWith('.crt') || file.endsWith('.zip'))
      .map(async (file) => {
        const filePath = path.join(tempDir, file);
        await fs.unlink(filePath);
      });

    await Promise.all(fileDeletionPromises);
  } catch (error) {
    console.error(error);
    throw error;
  }
};

export const handler = async (event: any) => {
  const data = await downloadCertificate();

  await writeToFile('certificate.crt', data['certificate.crt']);
  await writeToFile('ca_bundle.crt', data['ca_bundle.crt']);
  await zipFile('tmp', 'tmp/ssl_cert.zip');
  await uploadToS3('ssl_cert.zip', 'tmp/ssl_cert.zip');
  await cleanUpTmpDirectory();
};

handler({});
