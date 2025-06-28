package io;

import java.util.Arrays;
import java.util.Scanner;

public class ConsoleDataProvider implements DataProvider {

    private final Scanner scanner = new Scanner(System.in);

    @Override
    public DataSet readData() {
        while (true) {
            try {
                System.out.println("Введите значения x через пробел:");
                double[] xValues = parseLine(scanner.nextLine());

                System.out.println("Введите соответствующие значения y:");
                double[] yValues = parseLine(scanner.nextLine());

                validate(xValues, yValues);
                return new DataSet(xValues, yValues);

            } catch (IllegalArgumentException ex) {
                System.out.println("Ошибка: " + ex.getMessage());
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
