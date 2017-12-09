#include "opencv2/opencv.hpp"
#include "base64.cpp"

using namespace cv;
using namespace std;

int main(int, char**)
{
    VideoCapture cap(0);
    if(!cap.isOpened())  
        return -1;

    for(;;)
    {
        Mat frame;
        cap >> frame;
        vector<uchar> buf;
        imencode(".jpg", frame, buf);
        uchar *enc_msg = new uchar[buf.size()];
        for(unsigned int i=0; i < buf.size(); i++) enc_msg[i] = buf[i];
        string encoded = base64_encode(enc_msg, buf.size());
        cout << encoded << endl << endl;
    }
    return 0;
}
