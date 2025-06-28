package methods;

public class GaussForwardMethod implements InterpolationMethod {

    @Override
    public double value(double[] xs, double[] ys, double x) {

        int length = xs.length;
        int mid = length / 2;
        double step = xs[1] - xs[0];
        double tau = (x - xs[mid]) / step;

        double[][] diff = GaussUtils.forwardDifferences(ys);

        double result = diff[mid][0];
        double factor = 1.0;
        int sign = 1;

        for (int k = 1; k < length; k++) {

            if (k == 1) {
                factor = tau;
            } else {
                factor *= (k % 2 == 0) ? (tau + k / 2.0) : (tau - (k - 1) / 2.0);
                factor /= k;
            }

            int rowIndex = (k % 2 == 0) ? mid - k / 2 : mid - (k - 1) / 2;
            if (rowIndex < 0 || rowIndex >= length - k) {
                break;
            }

            result += sign * factor * diff[rowIndex][k];
            sign *= -1;
        }
        return result;
    }
}
