// pages/api/compress.js (updated error handling)
import { exec } from 'child_process';
import { promises as fs } from 'fs';
import { join } from 'path';
import formidable from 'formidable';
import { v4 as uuidv4 } from 'uuid';

export const config = {
  api: {
    bodyParser: false,
  },
};

export default async function handler(req, res) {
  if (req.method !== 'POST') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  try {
    // Create directories if they don't exist
    const uploadsDir = join(process.cwd(), 'uploads');
    const outputsDir = join(process.cwd(), 'outputs');
    
    await fs.mkdir(uploadsDir, { recursive: true });
    await fs.mkdir(outputsDir, { recursive: true });
    
    // Parse the form data
    const form = new formidable.IncomingForm();
    
    const [fields, files] = await new Promise((resolve, reject) => {
      form.parse(req, (err, fields, files) => {
        if (err) reject(err);
        resolve([fields, files]);
      });
    });
    
    if (!files.image) {
      return res.status(400).json({ error: 'No image file uploaded' });
    }
    
    const inputFile = files.image;
    const targetSize = fields.targetSize || '500';
    const resizeFactor = fields.resizeFactor || '1';
    
    // Generate unique filenames
    const fileId = uuidv4();
    const inputPath = join(uploadsDir, `${fileId}${inputFile.originalFilename}`);
    const outputPath = join(outputsDir, `${fileId}_compressed.jpg`);
    
    console.log('Input file path:', inputPath);
    console.log('Output file path:', outputPath);
    console.log('Target size:', targetSize);
    console.log('Resize factor:', resizeFactor);
    
    // Save the uploaded file
    await fs.copyFile(inputFile.filepath, inputPath);
    
    // Path to MATLAB script directory
    const matlabScriptDir = join(process.cwd(), 'matlabcompression');
    
    // Build MATLAB command
    // Note: Using single quotes for file paths to avoid Windows path issues
    const command = `matlab -nodisplay -nosplash -nodesktop -r "cd('${matlabScriptDir.replace(/\\/g, '\\\\')}'); jpegcompress('${inputPath.replace(/\\/g, '\\\\')}', '${outputPath.replace(/\\/g, '\\\\')}', ${targetSize}, ${resizeFactor}); exit;"`;
    
    console.log('Executing MATLAB command:', command);
    
    // Execute MATLAB command with detailed logging
    const matlabOutput = await new Promise((resolve, reject) => {
      exec(command, { maxBuffer: 1024 * 1024 * 10 }, (error, stdout, stderr) => {
        console.log('MATLAB stdout:', stdout);
        console.log('MATLAB stderr:', stderr);
        
        if (error) {
          console.error('MATLAB execution error:', error);
          reject(new Error(`MATLAB execution failed: ${error.message}`));
          return;
        }
        
        resolve(stdout);
      });
    });
    
    // Check if the output file exists
    try {
      await fs.access(outputPath);
    } catch (err) {
      throw new Error(`Output file not created. MATLAB output: ${matlabOutput}`);
    }
    
    // Return the compressed image
    const compressedImage = await fs.readFile(outputPath);
    res.setHeader('Content-Type', 'image/jpeg');
    res.setHeader('Content-Disposition', 'attachment; filename=compressed-image.jpg');
    res.send(compressedImage);
    
    // Clean up files
    fs.unlink(inputPath).catch(console.error);
    fs.unlink(outputPath).catch(console.error);
    
  } catch (error) {
    console.error('Error processing request:', error);
    res.status(500).json({ error: `Failed to process image: ${error.message}` });
  }
}