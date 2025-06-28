package methods;


public class LagrangeMethod implements InterpolationMethod {

    @Override
    public double value(double[] xs, double[] ys, double x) {
        double sum = 0.0;
        for (int i = 0; i < xs.length; i++) {
            double li = 1.0;
            for (int j = 0; j < xs.length; j++) {
                if (i == j) continue;
                li *= (x - xs[j]) / (xs[i] - xs[j]);
            }
            sum += ys[i] * li;
        }
        return sum;
    }
}
