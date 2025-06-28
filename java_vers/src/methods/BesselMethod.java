package methods;

public class BesselMethod implements InterpolationMethod {

    @Override
    public double value(double[] xs, double[] ys, double x) {

        int count = xs.length;
        int mid   = count / 2;                    // правая из двух центральных точек
        double h  = xs[1] - xs[0];
        double tau = (x - (xs[mid] + xs[mid - 1]) / 2.0) / h;

        double[][] diff = GaussUtils.forwardDifferences(ys);

        double result = (ys[mid] + ys[mid - 1]) / 2.0;

        if (mid - 1 >= 0) {
            result += tau * diff[mid - 1][1];
        }

        if (mid - 2 >= 0) {
            result += (tau * tau - 0.25)
                    * (diff[mid - 1][2] + diff[mid - 2][2]) / 4.0;
        }

        if (mid - 2 >= 0 && mid - 2 < count - 2) {
            result += (tau * (tau * tau - 1))
                    * diff[mid - 2][3] / 6.0;
        }

        if (mid - 3 >= 0 && mid - 3 < count - 3) {
            result += (tau * tau - 1) * (tau * tau - 4)
                    * (diff[mid - 2][4] + diff[mid - 3][4]) / 48.0;
        }

        return result;
    }
}
