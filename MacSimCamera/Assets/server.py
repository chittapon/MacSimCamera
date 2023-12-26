#!/usr/bin/env python3

import socket
import cv2

def center_crop(img, dim):
	"""Returns center cropped image
	Args:
	img: image to be center cropped
	dim: dimensions (width, height) to be cropped
	"""
	width, height = img.shape[1], img.shape[0]

	# process crop width and height for max available dimension
	crop_width = dim[0] if dim[0]<img.shape[1] else img.shape[1]
	crop_height = dim[1] if dim[1]<img.shape[0] else img.shape[0] 
	mid_x, mid_y = int(width/2), int(height/2)
	cw2, ch2 = int(crop_width/2), int(crop_height/2) 
	crop_img = img[mid_y-ch2:mid_y+ch2, mid_x-cw2:mid_x+cw2]
	return crop_img

# Socket creation
ser_sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)

host_ip = "127.0.0.1"
host_port = 8899
print(f"Server IP Address: {host_ip}")
socket_address = (host_ip, host_port)

ser_sock.bind(socket_address)
ser_sock.listen()

print(f"Server Serving at {ser_sock}")

while 1:
    client, addr = ser_sock.accept()
    print(f"Connected to Client@{addr}")

    if client:
        vid = cv2.VideoCapture(0)
        vid.set(3, 1280)
        vid.set(4, 720)
        while(vid.isOpened()):
            ret, frm = vid.read()
            
            try:
                width = 375
                height = 667
                crop_img = center_crop(frm, (width,height))
                #cv2.imshow('crop', crop_img)

                ret, buffer = cv2.imencode(".jpg", crop_img, [int(cv2.IMWRITE_JPEG_QUALITY),75])
                raw_data = buffer.tobytes()

                client.sendall(raw_data)
                print(f"Sent {len(raw_data)} bytes")
            except:
                print("Client disconnected")
                client.close()
                #cv2.destroyAllWindows()
                vid.release()
                break

            key = cv2.waitKey(1) & 0xff
            if key == ord('q'):
                client.close()

ser_sock.close()