import java.awt.BasicStroke;
import java.awt.BorderLayout;
import java.awt.GridLayout;
import java.awt.FlowLayout;
import java.awt.Font;
import java.awt.Color;
import java.awt.Graphics;
import java.awt.Graphics2D;
import java.awt.RenderingHints;
import java.awt.event.ActionListener;
import java.awt.event.ActionEvent;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;
import java.util.Random;
import java.math.BigDecimal;

import javax.swing.JFrame;
import javax.swing.JPanel;
import javax.swing.JLabel;
import javax.swing.JTextField;
import javax.swing.JButton;

import java.io.FileWriter;
import java.io.IOException;

import net.tinyos.message.*;
import net.tinyos.packet.*;
import net.tinyos.util.*;

public class Chart_test extends JFrame {

    private static final int MAX_VALUE = 180;// 接受到的数据最大值
    private static final int MAX_COUNT_OF_VALUES = 11;// 最多保存数据的个数
    private int frequency = 100;
    private wsnNode mySerial;
    // private
    private MyCanvas tempCanvas = new MyCanvas(20, 20, 450, 240, 0, 10, 1, 35, -20, 45, 5, 4, "温度／摄氏度");
    private MyCanvas humidCanvas = new MyCanvas(20, 20, 450, 260, 0, 10, 1, 35, 0, 100, 10, 2, "湿度／％");
    private MyPanel myPanel = new MyPanel();
    private SetPanel setPanel = new SetPanel();

    public Chart_test(String source) {
        super("数据显示：");

        this.setDefaultCloseOperation(EXIT_ON_CLOSE);
        setLayout(new GridLayout(2, 2));
        this.add(tempCanvas, BorderLayout.CENTER);
        this.add(myPanel, BorderLayout.CENTER);
        this.add(humidCanvas, BorderLayout.CENTER);
        this.add(setPanel, BorderLayout.CENTER);
        this.setBounds(100, 100, 950, 700);
        setPanel.frequencyText.setText(String.valueOf(frequency));
        this.setVisible(true);

        PhoenixSource phoenix;

        if (source == null) {
          phoenix = BuildSource.makePhoenix(PrintStreamMessenger.err);
        }
        else {
          phoenix = BuildSource.makePhoenix(source, PrintStreamMessenger.err);
        }
        MoteIF mif = new MoteIF(phoenix);
        mySerial = new wsnNode(mif);
    }

    // 画布重绘图
    class MyCanvas extends JPanel {
        private static final long serialVersionUID = 1L;

        // 框架起点坐标
        private final int FREAME_X;
        private final int FREAME_Y;
        private final int FREAME_WIDTH;// 横
        private final int FREAME_HEIGHT;// 纵

        // 原点坐标
        private final int Origin_X;
        private final int Origin_Y;

        // X,Y轴终点坐标
        private final int XAxis_X;
        private final int XAxis_Y;
        private final int YAxis_X;
        private final int YAxis_Y;

        // X轴上的时间分度值（1分度=40像素）
        private final int X_INTERVAL;
        private final int X_Min;
        private final int X_Max;
        private final int X_Factor;
        // Y轴上值
        private final int Y_INTERVAL;
        private final int Y_Min;
        private final int Y_Max;
        private final int Y_Factor;
        private final String Y_Title;

        private List<Double> values1 = new ArrayList<Double>();
        private List<Double> values2 = new ArrayList<Double>();

        MyCanvas(int frameX, int frameY, int width, int height, int xMin, int xMax, int xInterval, int xFactor, int yMin, int yMax, int yInterval, int yFactor, String yTitle) {
            FREAME_X = frameX;
            FREAME_Y = frameY;
            FREAME_WIDTH = width;
            FREAME_HEIGHT = height;
            Origin_X = FREAME_X + 50;
            Origin_Y = FREAME_Y + FREAME_HEIGHT - 30;
            XAxis_X = FREAME_X + FREAME_WIDTH - 30;
            XAxis_Y = Origin_Y;
            YAxis_X = Origin_X;
            YAxis_Y = FREAME_Y + 20;
            X_INTERVAL = xInterval;
            Y_INTERVAL = yInterval;
            X_Factor = xFactor;
            Y_Factor = yFactor;
            X_Min = xMin;
            X_Max = xMax;
            Y_Min = yMin;
            Y_Max = yMax;
            Y_Title = yTitle;
            // System.out.printf("%d %d %d %d", FREAME_WIDTH, FREAME_HEIGHT, XAxis_X, YAxis_Y);
        }

        public void addValue1(Double value) {
            // 循环的使用一个接受数据的空间
            values1.add(value);
            if (values1.size() > MAX_COUNT_OF_VALUES) {
                values1.remove(0);
            }
            repaint();
        }

        public void addValue2(Double value) {
            // 循环的使用一个接受数据的空间
            values2.add(value);
            if (values2.size() > MAX_COUNT_OF_VALUES) {
                values2.remove(0);
            }
            repaint();
        }

        public void paintComponent(Graphics g) {
            Graphics2D g2D = (Graphics2D) g;

            Color c = new Color(200, 70, 0);
            g.setColor(c);
            super.paintComponent(g);

            // 绘制平滑点的曲线
            g2D.setRenderingHint(RenderingHints.KEY_ANTIALIASING, RenderingHints.VALUE_ANTIALIAS_ON);
            // int w = FREAME_WIDTH;// 起始点
            int xDelta = X_INTERVAL * X_Factor;
            //System.out.printf("%f\n", xDelta);
            int length1 = values1.size();
            int length2 = values2.size();

            for (int i = 0; i < length1 - 1; ++i) {
                g2D.drawLine(Origin_X + xDelta * i, Origin_Y - (int)(values1.get(i) * Y_Factor),
                        Origin_X + xDelta * (i + 1), Origin_Y - (int)(values1.get(i + 1) * Y_Factor));
            }

            g.setColor(Color.BLUE);

            for (int i = 0; i < length2 - 1; ++i) {
                g2D.drawLine(Origin_X + xDelta * i, Origin_Y - (int)(values2.get(i) * Y_Factor),
                        Origin_X + xDelta * (i + 1), Origin_Y - (int)(values2.get(i + 1) * Y_Factor));
            }

            g.setColor(c);

            // 画坐标轴
            g2D.setStroke(new BasicStroke(Float.parseFloat("2.0F")));// 轴线粗度
            // X轴以及方向箭头
            g.drawLine(Origin_X, Origin_Y, XAxis_X, XAxis_Y);// x轴线的轴线
            g.drawLine(XAxis_X, XAxis_Y, XAxis_X - 5, XAxis_Y - 5);// 上边箭头
            g.drawLine(XAxis_X, XAxis_Y, XAxis_X - 5, XAxis_Y + 5);// 下边箭头

            // Y轴以及方向箭头
            g.drawLine(Origin_X, Origin_Y - Y_Min * Y_Factor, YAxis_X, YAxis_Y);
            g.drawLine(YAxis_X, YAxis_Y, YAxis_X - 5, YAxis_Y + 5);
            g.drawLine(YAxis_X, YAxis_Y, YAxis_X + 5, YAxis_Y + 5);

            // 画X轴上的时间刻度（从坐标轴原点起，每隔X_INTERVAL(时间分度)像素画一时间点，到X轴终点止）
            g.setColor(Color.BLUE);
            g2D.setStroke(new BasicStroke(Float.parseFloat("0.2f")));

            // X轴刻度依次变化情况
            // for (int i = Origin_X, j = 0; i < XAxis_X; i += X_INTERVAL, j += X_INTERVAL) {
            //     g.drawString(" " + j, i - 10, Origin_Y + 20);
            // }
            g.drawString("时间", XAxis_X + 5, XAxis_Y + 5);

            // 画Y轴上刻度
            for (int i = Origin_Y - Y_Min * Y_Factor, j = Y_Min; j <= Y_Max; i -= Y_INTERVAL * Y_Factor, j += Y_INTERVAL) {
                g.drawString(j + " ", Origin_X - 30, i + 3);
            }
            g.drawString(Y_Title, YAxis_X - 5, YAxis_Y - 5);
            // 画网格线
            g.setColor(Color.BLACK);
            // 坐标内部横线
            for (int i = Origin_Y - Y_Min * Y_Factor, j = Y_Min; j <= Y_Max; i -= Y_INTERVAL * Y_Factor, j += Y_INTERVAL) {
                g.drawLine(Origin_X, i, Origin_X + (X_Max - X_Min) * X_Factor, i);
            }
            // 坐标内部竖线
            for (int i = Origin_X, j = X_Min; j <= X_Max; i += X_INTERVAL * X_Factor, j += X_INTERVAL) {
                g.drawLine(i, Origin_Y - Y_Min * Y_Factor, i, Origin_Y - Y_Max * Y_Factor);
            }

        }
    }

    class MyPanel extends JPanel {
        private JTextField tempText1;
        private JTextField tempText2;
        private JTextField humidText1;
        private JTextField humidText2;
        private JTextField photoText1;
        private JTextField photoText2;
        MyPanel() {
            JLabel titleLabel = new JLabel("实时数据");
            titleLabel.setFont(new Font("宋体", Font.PLAIN, 25));
            titleLabel.setBounds(170, 30, 160, 30);
            JLabel sub1Label = new JLabel("采集点1");
            sub1Label.setFont(new Font("宋体", Font.PLAIN, 18));
            sub1Label.setBounds(135, 100, 80, 20);
            JLabel sub2Label = new JLabel("采集点2");
            sub2Label.setFont(new Font("宋体", Font.PLAIN, 18));
            sub2Label.setBounds(245, 100, 80, 20);
            JLabel tempLabel = new JLabel("温    度：");
            tempLabel.setBounds(50, 150, 140, 20);
            tempText1 = new JTextField();
            tempText1.setEditable(false);
            tempText1.setHorizontalAlignment(JTextField.CENTER);
            tempText1.setBounds(120, 150, 100, 20);
            tempText2 = new JTextField();
            tempText2.setEditable(false);
            tempText2.setHorizontalAlignment(JTextField.CENTER);
            tempText2.setBounds(230, 150, 100, 20);
            JLabel tempUnit= new JLabel("摄氏度");
            tempUnit.setBounds(340, 150, 100, 20);
            JLabel humidLabel= new JLabel("湿    度：");
            humidLabel.setBounds(50, 200, 140, 20);
            humidText1 = new JTextField();
            humidText1.setEditable(false);
            humidText1.setHorizontalAlignment(JTextField.CENTER);
            humidText1.setBounds(120, 200, 100, 20);
            humidText2 = new JTextField();
            humidText2.setEditable(false);
            humidText2.setHorizontalAlignment(JTextField.CENTER);
            humidText2.setBounds(230, 200, 100, 20);
            JLabel humidUnit= new JLabel("%");
            humidUnit.setBounds(340, 200, 100, 20);
            JLabel photoLabel= new JLabel("光照强度：");
            photoLabel.setBounds(50, 250, 140, 20);
            photoText1 = new JTextField();
            photoText1.setEditable(false);
            photoText1.setHorizontalAlignment(JTextField.CENTER);
            photoText1.setBounds(120, 250, 100, 20);
            photoText2 = new JTextField();
            photoText2.setEditable(false);
            photoText2.setHorizontalAlignment(JTextField.CENTER);
            photoText2.setBounds(230, 250, 100, 20);
            JLabel photoUnit= new JLabel("Lx");
            photoUnit.setBounds(340, 250, 100, 20);
            this.setLayout(null);
            this.add(titleLabel);
            this.add(sub1Label);
            this.add(sub2Label);
            this.add(tempLabel);
            this.add(tempText1);
            this.add(tempText2);
            this.add(tempUnit);
            this.add(humidLabel);
            this.add(humidText1);
            this.add(humidText2);
            this.add(humidUnit);
            this.add(photoLabel);
            this.add(photoText1);
            this.add(photoText2);
            this.add(photoUnit);
        }
    }

    class SetPanel extends JPanel {
        private JTextField frequencyText;
        private JTextField frequencyInput;
        private JButton frequencySumbit; // 待增加
        SetPanel() {
            JLabel titleLabel = new JLabel("采样频率");
            titleLabel.setFont(new Font("宋体", Font.PLAIN, 25));
            titleLabel.setBounds(170, 80, 160, 30);
            frequencyText = new JTextField();
            frequencyText.setFont(new Font("宋体", Font.PLAIN, 18));
            frequencyText.setEditable(false);
            frequencyText.setHorizontalAlignment(JTextField.CENTER);
            frequencyText.setBounds(140, 140, 120, 20);
            JLabel frequencyUnit = new JLabel("毫秒");
            frequencyUnit.setFont(new Font("宋体", Font.PLAIN, 18));
            frequencyUnit.setBounds(297, 140, 120, 20);
            frequencyInput = new JTextField();
            frequencyInput.setFont(new Font("宋体", Font.PLAIN, 18));
            frequencyInput.setHorizontalAlignment(JTextField.CENTER);
            frequencyInput.setBounds(140, 190, 120, 20);
            frequencySumbit = new JButton("修改");
            frequencySumbit.setFont(new Font("宋体", Font.PLAIN, 18));
            frequencySumbit.setBounds(270, 185, 90, 30);
            frequencySumbit.addActionListener(new ButtonAction());

            this.setLayout(null);
            this.add(titleLabel);
            this.add(frequencyText);
            this.add(frequencyUnit);
            this.add(frequencyInput);
            this.add(frequencySumbit);
        }
    }

    class ButtonAction implements ActionListener {
        public void actionPerformed(ActionEvent event) {
            // 修改频率按钮被点击，发送修改频率数据包
            if (event.getActionCommand() == "修改") {
                String frequencyStr = setPanel.frequencyInput.getText();
                // System.out.println(frequencyStr);
                frequency = Integer.parseInt(frequencyStr);
                setPanel.frequencyText.setText(frequencyStr);
                // 发送数据包
                mySerial.sendPacket();
            }
        }
    }

    public class wsnNode implements MessageListener {

      private MoteIF moteIF;
      private FileWriter fileWriter;
      private Double tempData1;
      private Double tempData2;
      private Double humidData1;
      private Double humidData2;
      private int getCount1 = 0;
      private int getCount2 = 0;
      private ArrayList<Integer> seqNoList1 = new ArrayList<Integer>();
      private ArrayList<Integer> seqNoList2 = new ArrayList<Integer>();

      private final int CALC_COUNT = 1000;
      private final int MAX_COUNT_OF_LIST = 3000;
      private final int FEQ_HEAD = 0x16cb;

      public wsnNode(MoteIF moteIF) {
        this.moteIF = moteIF;
        this.moteIF.registerListener(new SampleMsg(), this);
        try {
          this.fileWriter = new FileWriter("result.txt", true);
        }
        catch (IOException e) {
          e.printStackTrace();
          System.err.println("文件创建或打开失败，请重新启动程序！");
        }
      }

      public void sendPacket() {
        FreqMsg payload = new FreqMsg();
        payload.set_frequency(frequency);
        payload.set_head(FEQ_HEAD);
        try {
          moteIF.send(0, payload);
        }
        catch (IOException e) {
          e.printStackTrace();
          System.err.println("遇到问题，频率数据包发送失败！");
        }
      }

      public double dataFormat(double rawData) {
        BigDecimal bg = new BigDecimal(rawData);
        double f1 = bg.setScale(2, BigDecimal.ROUND_HALF_UP).doubleValue();
        return f1;
      }

      public void messageReceived(int to, Message message) {
        SampleMsg msg = (SampleMsg)message;
        String appendStr = String.format("%d %d %d %d %d %d\n", msg.get_nodeId(), msg.get_seqNo(), msg.get_temp(), msg.get_humidity(), msg.get_photo(), msg.get_time());
        // System.out.println(appendStr);
        try{
          fileWriter.write(appendStr);
          fileWriter.flush();
        }
        catch (IOException e) {
          e.printStackTrace();
          System.err.println("遇到问题，文件result.txt写入失败！");
        }
        double humidRaw = msg.get_humidity();
        if (msg.get_nodeId() == 1) {
          tempData1 = -40.1 + 0.01*msg.get_temp();
          tempData1 = dataFormat(tempData1);
          tempCanvas.addValue1(tempData1);
          myPanel.tempText1.setText(String.valueOf(tempData1));
          humidData1 = -4 + 4*humidRaw/100 + (-28/1000/10000)*(humidRaw*humidRaw);
          humidData1 = (tempData1-25)*(1/100+8*humidRaw/100/1000)+humidData1;
          humidData1 = dataFormat(humidData1);
          humidCanvas.addValue1(humidData1);
          myPanel.humidText1.setText(String.valueOf(humidData1));
          myPanel.photoText1.setText(String.valueOf(msg.get_photo()));
        }
        else {
          tempData2 = -40.1 + 0.01*msg.get_temp();
          tempData2 = dataFormat(tempData2);
          tempCanvas.addValue2(tempData2);
          myPanel.tempText2.setText(String.valueOf(tempData2));
          humidData2 = -4 + 4*humidRaw/100 + (-28/1000/10000)*(humidRaw*humidRaw);
          humidData2 = (tempData2-25)*(1/100+8*humidRaw/100/1000)+humidData2;
          humidData2 = dataFormat(humidData2);
          humidCanvas.addValue2(humidData2);
          myPanel.humidText2.setText(String.valueOf(humidData2));
          myPanel.photoText2.setText(String.valueOf(msg.get_photo()));
        }
        if (msg.get_nodeId() == 1) {
          seqNoList1.add(msg.get_seqNo());
          getCount1++;
        }
        else {
          seqNoList2.add(msg.get_seqNo());
          getCount2++;
        }
        if (getCount1 == CALC_COUNT) {
          System.out.printf("节点1丢包率：%f\n", lossRate1());
        }
        else if (getCount2 == CALC_COUNT) {
          System.out.printf("节点2丢包率：%f\n", lossRate2());
        }
      }

      public double lossRate1() {
        Collections.sort(seqNoList1);
        int getNum = CALC_COUNT, lossNum = 0;

        for (int i = CALC_COUNT - 1; i > 0; i--) {
          if (!seqNoList1.get(i).equals(seqNoList1.get(i - 1) + 1)) {
            if (seqNoList1.get(i).equals(seqNoList1.get(i - 1))) {
              getNum--;
            }
            else {
              lossNum += seqNoList1.get(i) - seqNoList1.get(i - 1) - 1;
            }
          }
        }
        seqNoList1.clear();
        getCount1 = 0;
        return (double)lossNum / (lossNum + getNum);
      }

      public double lossRate2() {
        Collections.sort(seqNoList2);
        int getNum = CALC_COUNT, lossNum = 0;

        for (int i = CALC_COUNT - 1; i > 0; i--) {
          if (!seqNoList2.get(i).equals(seqNoList2.get(i - 1) + 1)) {
            if (seqNoList2.get(i).equals(seqNoList2.get(i - 1))) {
              getNum--;
            }
            else {
              lossNum += seqNoList2.get(i) - seqNoList2.get(i - 1) - 1;
            }
          }
        }
        seqNoList2.clear();
        getCount2 = 0;
        return (double)lossNum / (lossNum + getNum);
      }
    }

    public static void main(String[] args) {
        // TODO Auto-generated method stub
        String source = null;
        if (args.length == 2) {
          if (!args[0].equals("-comm")) {
            System.err.println("usage: wsnNode [-comm <source>]");
            System.exit(1);
          }
          source = args[1];
        }
        else if (args.length != 0) {
          System.err.println("usage: wsnNode [-comm <source>]");
          System.exit(1);
        }

        Chart_test chart_test = new Chart_test(source);
    }
}
