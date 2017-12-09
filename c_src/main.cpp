#include "opencv2/opencv.hpp"
#include "base64.cpp"

// This is a quick fix to make sure that when Erlang Exists this process dies.
#include <signal.h>
#include <sys/prctl.h>
#include <linux/prctl.h>

using namespace cv;
using namespace std;

int main(int, char *argv[])
{
  prctl(PR_SET_PDEATHSIG, SIGHUP);

  char *p;
  int cameraID = strtol(argv[1], &p, 10);

  if (errno != 0 || *p != '\0' || cameraID > INT_MAX) {
    return -2;
  }

  VideoCapture cap(cameraID);

  if(!cap.isOpened()) {
    return -1;
  }

  while(true)
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
