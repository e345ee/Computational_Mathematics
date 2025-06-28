package methods;

public class GaussBackwardMethod implements InterpolationMethod {

    @Override
    public double value(double[] xs, double[] ys, double x) {
        int length = xs.length;
        int mid = length / 2;
        double step = xs[1] - xs[0];
        double center = (xs[mid] + xs[mid - 1]) / 2.0;
        double tau = (x - center) / step;

        double[][] diff = GaussUtils.forwardDifferences(ys);

        double result = (ys[mid] + ys[mid - 1]) / 2.0;

        double term = tau;
        result += term * diff[mid - 1][1];

        for (int k = 2; k < length; k++) {
            term *= (tau * tau - (k / 2.0) * (k / 2.0));
            term /= k;

            int rowA = mid - k / 2;
            int rowB = mid - 1 - k / 2;
            if (rowA < 0 || rowB < 0 || rowA >= length - k || rowB >= length - k) {
                break;
            }

            double average = (diff[rowA][k] + diff[rowB][k]) / 2.0;
            result += term * average;
        }
        return result;
    }
}




