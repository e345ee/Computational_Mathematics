package methods;

public class NewtonForwardMethod implements InterpolationMethod {

    @Override
    public double value(double[] xs, double[] ys, double x) {
        int size = xs.length;
        double step = xs[1] - xs[0];
        double tau = (x - xs[0]) / step;

        double[][] diff = GaussUtils.forwardDifferences(ys);

        double result = diff[0][0];
        double factor = 1.0;

        for (int k = 1; k < size; k++) {
            factor *= (tau - (k - 1)) / k;
            result += factor * diff[0][k];
        }
        return result;
    }
}
