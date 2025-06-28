import io.*;
import methods.*;
import plot.GraphPlotter;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Scanner;
import java.util.function.DoubleUnaryOperator;

public class Main {

    private static final Scanner INPUT = new Scanner(System.in);

    public static void main(String[] args) {

        do {
            DataProvider provider = chooseProvider();
            DataSet data = provider.readData();

            double[][] differences = methods.GaussUtils.forwardDifferences(data.ys());
            printDifferences(data.xs(), differences);

            double targetX = askX();

            InterpolationMethod lagrange   = new LagrangeMethod();
            InterpolationMethod newtonFwd  = new NewtonForwardMethod();
            InterpolationMethod newtonBwd  = new NewtonBackwardMethod();
            InterpolationMethod gaussOne   = new GaussForwardMethod();
            InterpolationMethod gaussTwo   = new GaussBackwardMethod();
            InterpolationMethod stirling   = new StirlingMethod();
            InterpolationMethod bessel     = new BesselMethod();

            System.out.printf("%nЗначения в точке x = %.6f%n", targetX);
            printValue(lagrange,  "Лагранж        ", data, targetX);
            printValue(newtonFwd, "Ньютон вперёд  ", data, targetX);
            printValue(newtonBwd, "Ньютон назад   ", data, targetX);
            printValue(gaussOne,  "Гаусс (1-я)    ", data, targetX);
            printValue(gaussTwo,  "Гаусс (2-я)    ", data, targetX);
            printValue(stirling,  "Стирлинг       ", data, targetX);
            printValue(bessel,    "Бессель        ", data, targetX);

            DoubleUnaryOperator exactFunc = null;
            if (provider instanceof FunctionDataProvider p) {
                exactFunc = p.lastFunction();
            }

            Map<String, InterpolationMethod> curves = new LinkedHashMap<>();
            curves.put("Лагранж", lagrange);
            curves.put("Ньютон ↑", newtonFwd);
            curves.put("Ньютон ↓", newtonBwd);
            curves.put("Гаусс 1",  gaussOne);
            curves.put("Гаусс 2",  gaussTwo);
            curves.put("Стирлинг", stirling);
            curves.put("Бессель",  bessel);

            double left  = data.xs()[0] - 0.1;
            double right = data.xs()[data.xs().length - 1] + 0.1;

            GraphPlotter.show(data, exactFunc, new LinkedHashMap<>(curves), left, right);

        } while (repeatRequest());
    }

    private static DataProvider chooseProvider() {
        while (true) {
            System.out.println(
                    "Как ввести таблицу?\n"
                            + "  1 — с клавиатуры\n"
                            + "  2 — из файла\n"
                            + "  3 — сгенерировать по функции");
            String answer = INPUT.nextLine().trim();
            switch (answer) {
                case "1": return new ConsoleDataProvider();
                case "2": return new FileDataProvider();
                case "3": return new FunctionDataProvider();
                default : System.out.println("Некорректный выбор.");
            }
        }
    }

    private static double askX() {
        while (true) {
            System.out.print("Введите x, в котором нужно интерполировать: ");
            try {
                return Double.parseDouble(INPUT.nextLine().trim());
            } catch (NumberFormatException ignored) {
                System.out.println("Некорректное число.");
            }
        }
    }

    private static boolean repeatRequest() {
        System.out.print("Повторить вычисления? (y/n): ");
        return INPUT.nextLine().trim().equalsIgnoreCase("y");
    }

    private static void printValue(InterpolationMethod method, String label,
                                   DataSet data, double x) {
        double value = method.value(data.xs(), data.ys(), x);
        System.out.printf("%s→ %.6f%n", label, value);
    }

    private static void printDifferences(double[] xs, double[][] diff) {
        int n = xs.length;
        System.out.println("\nТаблица конечных разностей:");
        System.out.printf("%10s %10s", "x", "y");
        for (int k = 1; k < n; k++) {
            System.out.printf(" %10s", "D" + k + "y");
        }
        System.out.println();
        for (int i = 0; i < n; i++) {
            System.out.printf("%10.4f %10.4f", xs[i], diff[i][0]);
            for (int k = 1; k < n - i; k++) {
                System.out.printf(" %10.4f", diff[i][k]);
            }
            System.out.println();
        }
    }
}
