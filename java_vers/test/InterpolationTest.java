import io.DataSet;
import methods.*;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

import static org.junit.jupiter.api.Assertions.*;

class InterpolationTest {

    private static final double EPS = 1e-6;

    /* ---------- helpers ---------- */

    private static DataSet quadraticData() {
        double[] xs = {0, 1, 2, 3, 4};
        double[] ys = {0, 1, 4, 9, 16};         // y = x^2
        return new DataSet(xs, ys);
    }

    private static DataSet sineData() {
        double[] xs = {0, Math.PI / 2, Math.PI, 3 * Math.PI / 2};
        double[] ys = {0, 1, 0, -1};            // y = sin x
        return new DataSet(xs, ys);
    }

    /* ---------- x^2 tests ---------- */

    @Test
    @DisplayName("x^2 — все методы совпадают (x=2.5)")
    void quadraticAllMethods() {
        DataSet data = quadraticData();
        double x = 2.5;
        double expected = x * x;                // 6.25

        assertAll(
                () -> assertEquals(expected, new LagrangeMethod()
                        .value(data.xs(), data.ys(), x), EPS),

                () -> assertEquals(expected, new NewtonForwardMethod()
                        .value(data.xs(), data.ys(), x), EPS),

                () -> assertEquals(expected, new NewtonBackwardMethod()
                        .value(data.xs(), data.ys(), x), EPS),

                () -> assertEquals(expected, new GaussForwardMethod()
                        .value(data.xs(), data.ys(), x), EPS),

                () -> assertEquals(expected, new GaussBackwardMethod()
                        .value(data.xs(), data.ys(), x), EPS),

                () -> assertEquals(expected, new StirlingMethod()
                        .value(data.xs(), data.ys(), x), EPS),

                () -> assertEquals(expected, new BesselMethod()
                        .value(data.xs(), data.ys(), x), EPS)
        );
    }

    /* ---------- sin(x) tests ---------- */

    @Test
    @DisplayName("sin x — Лагранж vs Ньютон (x=π/4)")
    void sineLagrangeVsNewton() {
        DataSet data = sineData();
        double x = Math.PI / 4;
        double expected = Math.sin(x);          // ~0.7071

        double lagrange = new LagrangeMethod()
                .value(data.xs(), data.ys(), x);

        double newton = new NewtonForwardMethod()
                .value(data.xs(), data.ys(), x);

        assertAll(
                () -> assertEquals(expected, lagrange, 1e-3), // sin интерполируем 4-мя точками
                () -> assertEquals(lagrange, newton, 1e-6)
        );
    }
}
