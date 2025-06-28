package io;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Arrays;
import java.util.Scanner;

public class FileDataProvider implements DataProvider {

    private final Scanner scanner = new Scanner(System.in);

    @Override
    public DataSet readData() {
        while (true) {
            System.out.print("Укажите путь к файлу с таблицей: ");
            String filePath = scanner.nextLine().trim();

            try {
                var lines = Files.readAllLines(Path.of(filePath));
                if (lines.size() < 2) {
                    throw new IllegalArgumentException("В файле должно быть минимум две строки.");
                }

                double[] xValues = parseLine(lines.get(0));
                double[] yValues = parseLine(lines.get(1));

                validate(xValues, yValues);
                return new DataSet(xValues, yValues);

            } catch (IOException e) {
                System.out.println("Ошибка чтения файла: " + e.getMessage());
            } catch (NumberFormatException e) {
                System.out.println("Ошибка формата чисел в файле.");
            } catch (IllegalArgumentException e) {
                System.out.println("Ошибка: " + e.getMessage());
            }
        }
    }

    private static double[] parseLine(String line) {
        return Arrays.stream(line.trim().split("\\s+"))
                .mapToDouble(Double::parseDouble)
                .toArray();
    }

    private static void validate(double[] xValues, double[] yValues) {
        if (xValues.length < 2) {
            throw new IllegalArgumentException("Нужно минимум две точки.");
        }
        if (xValues.length != yValues.length) {
            throw new IllegalArgumentException("Количество x и y должно совпадать.");
        }

        final double tolerance = 1e-12;
        for (int i = 0; i < xValues.length - 1; i++) {
            for (int j = i + 1; j < xValues.length; j++) {
                if (Math.abs(xValues[i] - xValues[j]) < tolerance) {
                    throw new IllegalArgumentException("Найдены повторяющиеся x-значения.");
                }
            }
        }
    }
}
