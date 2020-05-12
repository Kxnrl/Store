# Help
# import vdf by running pip3 install vdf in console.
# place your items.txt file into the dir with this scirpt.
# edit INPUT_FILE_NAME & OUTPUT_FILE_NAME
# python3 create_update.py

import vdf
import os

CURRECT_DIR = os.path.dirname(os.path.realpath(__file__))
INPUT_FILE_NAME = "items.txt"
OUTPUT_FILE_NAME = "update.sql"

items = vdf.load(open("{}/{}".format(CURRECT_DIR, INPUT_FILE_NAME)))
output = open("{}/{}".format(CURRECT_DIR, OUTPUT_FILE_NAME),"w+")

items = {**items["Store"]["VIP Area"], **items["Store"]["Non-VIP Area"]} # Removing some pointless indexing.

counter = 0
for key, value in items.items():
    for item in value:
        counter += 1

        print("Looped over {} items".format(counter))

        postion = items[key][item]

        write = True
        # Pets expects old uid to be unique_id, sometimes unique_id isn't given.
        if postion["type"] == "pet" and postion.get("unique_id"):
            old_id = postion["unique_id"]
        # Tracers expect color to be the old uid.
        elif postion["type"] == "tracer":
            old_id = postion["color"]
        else:
            # If model comes first use that as the old uid.
            if postion.get("model"):
                old_id = postion["model"]
            # Other use material as the old uid.
            elif postion.get("material"):
                old_id = postion["material"]
            # No old uid to set.
            else:
                print("{} is missing a material or model".format(postion["uid"]))
                write = False

        if write == True:
            output.write("\nUPDATE `store_items` SET `unique_id` = '{}' WHERE `type` = '{}' AND `unique_id` = '{}';".format(postion["uid"], postion["type"], old_id))

output.close()
