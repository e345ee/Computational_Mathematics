package methods;

public final class GaussUtils {

    private GaussUtils() {}

    public static double[][] forwardDifferences(double[] yValues) {
        int size = yValues.length;
        double[][] diff = new double[size][size];
        for (int i = 0; i < size; i++) {
            diff[i][0] = yValues[i];
        }
        for (int order = 1; order < size; order++) {
            for (int row = 0; row < size - order; row++) {
                diff[row][order] = diff[row + 1][order - 1] - diff[row][order - 1];
            }
        }
        return diff;
    }

    public static double[][] dividedDifferences(double[] xValues, double[] yValues) {
        int size = yValues.length;
        double[][] diff = new double[size][size];
        for (int i = 0; i < size; i++) {
            diff[i][0] = yValues[i];
        }
        for (int order = 1; order < size; order++) {
            for (int row = 0; row < size - order; row++) {
                diff[row][order] =
                        (diff[row + 1][order - 1] - diff[row][order - 1])
                                / (xValues[row + order] - xValues[row]);
            }
        }
        return diff;
    }
}
