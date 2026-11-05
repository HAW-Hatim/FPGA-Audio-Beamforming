import math, numpy as np
#distance = float(input("Please enter distance between two elements: "))
#elements = int(input("Please enter array elements: "))
#angle_distance = float(input("Distance between angles (Range is 0-90°): "))
speed_sound = 343 # m/s
elements = 5

# Time delay from microphone zero to N
# Microphone zero at 90 degrees, microphone N at -90°
# Center should be in the center, currently reference point is microphone with index 0
def time_delay(distance, elements, angle):
    N = elements # Just for namings sake
    delays = []
    result = 0
    # this loop will only store values from (N/2-1) to 0
    # Other side can be mirrored, since our beam will be created in the center of the physical board
    for n in range(N):
        result = (((n-((N-1)/2))* distance) * math.sin(angle))/speed_sound
        delays.append(result)
    return delays
    

def angle_and_delay_sweep(angle_distance, distance, elements):
    angle_list = np.arange(-90,90 + angle_distance ,angle_distance)
    angle_to_delay_array = []#

    for angle in angle_list:
        angle_rad = math.radians(angle)
        delays = time_delay(distance, elements, angle_rad)
        # Only positive delays in reference to our center -> smallest delay to everyone
        min_delay = abs(min(delays))
        cleaned_delay = [delay + min_delay for delay in delays]
        angle_to_delay_array.append(cleaned_delay)
    return angle_to_delay_array

output_list = angle_and_delay_sweep(1, 0.04, 5)

start_angle = -90

# If angle < 90°
# array element 1 (Indexing with) is the normal value with "delay" -> array 2 = 2 * "delay" and so on; array 0 is 0
# For angles bigger element N - 1 is our normal value named delay

with open("samples.txt", "a") as f:
    for lists in output_list:
        print(str(start_angle) + "°: ")
        f.write(str(start_angle) + "°: \n")

        i = elements -1

        for item in lists:
        
            sample = int(item/(0.000020))
        

            
            print("Array element " + str(i) + " delay in s: " + str(item))
            f.write("Array element " + str(i) + " Sample(s): " + str(sample) + "\n ")
            i -= 1
        start_angle += 1
