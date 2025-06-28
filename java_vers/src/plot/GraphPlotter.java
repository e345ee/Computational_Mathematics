package plot;

import io.DataSet;
import methods.InterpolationMethod;
import org.jfree.chart.ChartFactory;
import org.jfree.chart.ChartPanel;
import org.jfree.chart.JFreeChart;
import org.jfree.chart.plot.PlotOrientation;
import org.jfree.chart.plot.XYPlot;
import org.jfree.chart.renderer.xy.XYLineAndShapeRenderer;
import org.jfree.data.xy.XYSeries;
import org.jfree.data.xy.XYSeriesCollection;

import javax.swing.JFrame;
import javax.swing.WindowConstants;
import java.awt.BasicStroke;
import java.awt.Color;
import java.awt.Paint;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.function.DoubleUnaryOperator;

public final class GraphPlotter {

    private GraphPlotter() {}

    private static final Paint[] COLORS = {
            Color.BLUE, Color.GREEN.darker(), Color.ORANGE,
            Color.MAGENTA, Color.CYAN.darker(),
            new Color(128, 0, 0), new Color(0, 128, 0)
    };

    public static void show(DataSet data,
                            DoubleUnaryOperator trueFunction,
                            LinkedHashMap<String, InterpolationMethod> methods,
                            double left, double right) {

        XYSeriesCollection collection = new XYSeriesCollection();

        if (trueFunction != null) {
            XYSeries trueSeries = new XYSeries("f(x)");
            fillSeries(trueSeries, trueFunction, left, right);
            collection.addSeries(trueSeries);
        }

        List<String> names = new ArrayList<>(methods.keySet());
        for (String name : names) {
            XYSeries series = new XYSeries(name);
            InterpolationMethod method = methods.get(name);
            fillSeries(series, x -> method.value(data.xs(), data.ys(), x), left, right);
            collection.addSeries(series);
        }

        XYSeries nodeSeries = new XYSeries("Узлы");
        for (int i = 0; i < data.xs().length; i++) {
            nodeSeries.add(data.xs()[i], data.ys()[i]);
        }
        collection.addSeries(nodeSeries);

        JFreeChart chart = ChartFactory.createXYLineChart(
                "Интерполяция", "x", "y",
                collection, PlotOrientation.VERTICAL,
                true, true, false);

        XYPlot plot = chart.getXYPlot();
        XYLineAndShapeRenderer renderer = new XYLineAndShapeRenderer();

        int index = 0;

        if (trueFunction != null) {
            renderer.setSeriesPaint(index, Color.RED);
            renderer.setSeriesLinesVisible(index, true);
            renderer.setSeriesShapesVisible(index, false);
            index++;
        }

        for (int i = 0; i < names.size(); i++, index++) {
            renderer.setSeriesPaint(index, COLORS[i % COLORS.length]);
            renderer.setSeriesLinesVisible(index, true);
            renderer.setSeriesShapesVisible(index, false);
            renderer.setSeriesStroke(index, new BasicStroke(
                    2f, BasicStroke.CAP_ROUND, BasicStroke.JOIN_ROUND,
                    1f, new float[]{6f, 4f * (i % 2)}, 0f));
        }

        renderer.setSeriesLinesVisible(index, false);
        renderer.setSeriesShapesVisible(index, true);
        renderer.setSeriesShape(index, new java.awt.geom.Ellipse2D.Double(-3, -3, 6, 6));
        renderer.setSeriesPaint(index, Color.BLACK);

        plot.setRenderer(renderer);

        JFrame frame = new JFrame("Графики интерполяции");
        frame.setDefaultCloseOperation(WindowConstants.DISPOSE_ON_CLOSE);
        frame.add(new ChartPanel(chart));
        frame.pack();
        frame.setLocationRelativeTo(null);
        frame.setVisible(true);
    }

    private static void fillSeries(XYSeries series,
                                   DoubleUnaryOperator function,
                                   double left, double right) {
        int points = 400;
        double step = (right - left) / points;
        for (int i = 0; i <= points; i++) {
            double x = left + i * step;
            series.add(x, function.applyAsDouble(x));
        }
    }
}
