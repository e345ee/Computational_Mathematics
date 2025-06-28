package methods;

public class StirlingMethod implements InterpolationMethod {

    private static final double EPS = 1e-12;

    @Override
    public double value(double[] xs, double[] ys, double x) {

        int n = xs.length;
        if (n < 3) {
            throw new IllegalArgumentException("Stirling interpolation requires at least three nodes.");
        }

        int mid   = n / 2;
        double h  = xs[1] - xs[0];
        double t  = (x - xs[mid]) / h;
        double[][] d = GaussUtils.forwardDifferences(ys);

        double result = ys[mid];
        double term;


        if (mid - 1 >= 0) {
            term = t * (d[mid][1] + d[mid - 1][1]) / 2.0;
            result += term;
            if (Math.abs(term) < EPS) return result;
        }


        if (mid - 1 >= 0 && mid - 1 < n - 1) {
            term = t * t * d[mid - 1][2] / 2.0;
            result += term;
            if (Math.abs(term) < EPS) return result;
        }


        if (mid - 2 >= 0 && mid - 1 < n - 2) {
            term = t * (t * t - 1) * (d[mid - 1][3] + d[mid - 2][3]) / 12.0;
            result += term;
            if (Math.abs(term) < EPS) return result;
        }


        if (n >= 5 && mid - 2 >= 0 && mid - 2 < n - 3) {
            term = t * t * (t * t - 1) * d[mid - 2][4] / 24.0;
            result += term;
        }

        return result;
    }
}
