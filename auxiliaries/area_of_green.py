from datetime import datetime
import cv2
import sys
import numpy as np
import matplotlib.pyplot as plt
from scipy.signal import kaiserord, lfilter, firwin, find_peaks, butter, filtfilt


# 得到一个矩形区域的绿色通道值的平均值，point1和point2分别是左上角和右下角的点
def green_of_area(image, point1_row, point1_column, point2_row, point2_column):
    x = point1_row
    y = point1_column
    sum1 = 0
    image_part = image[point1_row:point2_row,point1_column:point2_column,1]
    sum1 = np.sum(image_part)
    ave = sum1 / ((point2_row - point1_row) * (point2_column - point1_column))
    return ave


# 处理视频的每一帧
def radio_process(filename, point1_row, point1_column, point2_row, point2_column):
    video_capture = cv2.VideoCapture()
    video_capture.open(filename)
    fps = video_capture.get(cv2.CAP_PROP_FPS)
    width = video_capture.get(cv2.CAP_PROP_FRAME_WIDTH)
    height = video_capture.get(cv2.CAP_PROP_FRAME_HEIGHT)
    frames = video_capture.get(cv2.CAP_PROP_FRAME_COUNT)
    print('fps =', fps, 'width=', width, 'height =', height, 'frames =', frames)

    results = []
    for i in range(0,int(frames)):
        ret, frame = video_capture.read()
        result = green_of_area(frame, point1_row, point1_column, point2_row, point2_column)
        results.append(result)
    return results


if __name__ == '__main__':
    start = datetime.now()
#    filename = 'finger1.mp4'  # 文件名
    filename = sys.argv[1]
    results = radio_process(filename, 0, 0, 1080, 1920)

    # 计算执行时间
    end = datetime.now()
    print('running time:', end - start)

    results = np.array(results)
    plt.figure(1)
    x = np.arange(len(results))
    plt.plot(x, results, 'b')
    plt.show()
