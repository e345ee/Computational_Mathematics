package io;

import java.util.Map;
import java.util.Scanner;
import java.util.function.DoubleUnaryOperator;

public class FunctionDataProvider implements DataProvider {

    private final Scanner scanner = new Scanner(System.in);
    private DoubleUnaryOperator selectedFunction;

    private static final Map<Integer, FunctionItem> FUNCTIONS = Map.of(
            1, new FunctionItem("sin(x)", Math::sin),
            2, new FunctionItem("cos(x)", Math::cos),
            3, new FunctionItem("exp(x)", Math::exp),
            4, new FunctionItem("x^2",   x -> x * x)
    );

    @Override
    public DataSet readData() {
        while (true) {
            try {
                int choice = chooseFunction();
                FunctionItem item = FUNCTIONS.get(choice);
                selectedFunction = item.function();

                System.out.print("Введите a (начало интервала): ");
                double a = Double.parseDouble(scanner.nextLine().trim());

                System.out.print("Введите b (конец интервала): ");
                double b = Double.parseDouble(scanner.nextLine().trim());
                if (a >= b) {
                    throw new IllegalArgumentException("a должно быть меньше b.");
                }

                System.out.print("Введите количество точек n (≥ 2): ");
                int n = Integer.parseInt(scanner.nextLine().trim());
                if (n < 2) {
                    throw new IllegalArgumentException("n должно быть ≥ 2.");
                }

                double step = (b - a) / (n - 1);
                double[] xValues = new double[n];
                double[] yValues = new double[n];
                for (int i = 0; i < n; i++) {
                    xValues[i] = a + i * step;
                    yValues[i] = selectedFunction.applyAsDouble(xValues[i]);
                }
                return new DataSet(xValues, yValues);

            } catch (NumberFormatException e) {
                System.out.println("Ошибка: это не число. Попробуйте ещё раз.");
            } catch (IllegalArgumentException e) {
                System.out.println("Ошибка: " + e.getMessage());
            }
        }
    }

    private int chooseFunction() {
        while (true) {
            System.out.println("Выберите функцию:");
            FUNCTIONS.forEach((k, v) ->
                    System.out.printf("  %d — %s%n", k, v.name()));
            System.out.print("Ваш выбор: ");
            try {
                int num = Integer.parseInt(scanner.nextLine().trim());
                if (FUNCTIONS.containsKey(num)) {
                    return num;
                }
            } catch (NumberFormatException ignored) {
            }
            System.out.println("Некорректный номер, попробуйте ещё раз.");
        }
    }

    private record FunctionItem(String name, DoubleUnaryOperator function) {}

    public DoubleUnaryOperator lastFunction() {
        return selectedFunction;
    }
}

