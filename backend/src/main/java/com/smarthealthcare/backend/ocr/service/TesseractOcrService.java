package com.smarthealthcare.backend.ocr.service;

import lombok.extern.slf4j.Slf4j;
import net.sourceforge.tess4j.ITesseract;
import net.sourceforge.tess4j.Tesseract;
import net.sourceforge.tess4j.TesseractException;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import javax.imageio.ImageIO;
import java.awt.image.BufferedImage;
import java.io.File;
import java.io.IOException;

@Slf4j
@Service
public class TesseractOcrService implements OcrService {

    @Value("${tesseract.data.path}")
    private String tessDataPath;

    @Override
    public String extractText(File imageFile) {

        ITesseract tesseract = new Tesseract();

        tesseract.setDatapath(tessDataPath);
        tesseract.setLanguage("eng");

        try {

            BufferedImage image = ImageIO.read(imageFile);

            if (image == null) {
                throw new RuntimeException("ImageIO could not read image.");
            }

            log.debug("Image info — Width: {}, Height: {}",
                    image.getWidth(), image.getHeight());

            return tesseract.doOCR(image);

        } catch (IOException | TesseractException e) {
            throw new RuntimeException("OCR failed", e);
        }
    }
}