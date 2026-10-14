# Fall Festival Roster

## Setup

I ran my app using the Android emulator. The app uses SQLite to save the guests.

## Test Results

| Test | What I Did | What Should Happen | What Happened | Result |
|---|---|---|---|---|
| T1 | Refreshed the app with no guests | Count should be 0 | The count was 0 and it said "No festival guests yet" | Pass |
| T2 | Added River age 21 and River age 34 | Both should be added with different IDs | River age 21 got ID 1 and River age 34 got ID 2. The count was 2 | Pass |
| T3 | Changed ID 2 to age 99 but canceled it. Then changed it to 35 and saved | Cancel should keep the old age and save should change it to 35 | Cancel kept the age at 34. After I saved it again, ID 2 changed to age 35. ID 1 stayed age 21 | Pass |
| T4 | Force stopped the app and opened it again | The two Rivers should still be saved | Both Rivers were still there with the same IDs and ages. The count was still 2 | Pass |
| T5 | Tried to delete ID 1 but canceled. Then I deleted it again and confirmed it | Cancel should not delete it and confirming should delete it | Cancel kept both guests. When I confirmed the second time, ID 1 was deleted and the count went to 1 | Pass |
| T6 | Tried the invalid inputs and then added Acorn age 0 and Oak age 130 | Bad inputs should not work but ages 0 and 130 should work | The bad inputs did not get added. Acorn got ID 3 and Oak got ID 4. The final count was 3 | Pass |

## T6 Inputs

- Blank/space name with age 21 - Rejected
- Maple with abc - Rejected
- Maple with 1.5 - Rejected
- Maple with -1 - Rejected
- Maple with 131 - Rejected
- Acorn with age 0 - Accepted, ID 3
- Oak with age 130 - Accepted, ID 4

## 1. The Disappearing-Data Mystery

Before I restarted the app, I thought both River guests would still be there because they were saved in SQLite. I had River age 21 as ID 1 and River age 35 as ID 2, and my count was 2. I stopped the app, force stopped it, and opened it again. Both Rivers were still there with the same information. The app opens the database with init() and then reads the saved guests with queryAllRows(). If I opened the app again and the count was 0, then that would show the data did not come back from SQLite.

Evidence: evidence/T4_before.png and evidence/T4_after.png

## 2. Two Rivers, One Wrong Edit

Having two people named River showed me why the ID matters. One River was ID 1 and the other was ID 2. I changed ID 2 to 99 but canceled it, so it stayed at 34. Then I edited ID 2 again and saved the age as 35. Only ID 2 changed and ID 1 stayed the same. This showed that the ID is what tells the app which person to change.

## 3. My Usability Walkthrough

I thought the app was pretty easy to use because everything was on one screen. I could add somebody, edit them, delete them, or refresh the list. I also liked that it would not let me put something like "abc" for an age. One thing I would change is adding a message when I cancel deleting somebody so I know for sure that nothing happened.

Evidence: evidence/T6_invalid.png

## Evidence

- T4_before.png
- T4_after.png
- T6_invalid.png
- analysis_output.txt

## Local Storage Lab – Part II

### What I Did

For Part II, I upgraded my Flutter app from SQLite database version 1 to version 2. I added folders and cards while keeping my original guest records from Part I.

I also made screens where users can add folders, add cards, edit cards, and delete cards or folders.

### Testing (T1–T6)

**T1 – Database Migration (Passed)**

I upgraded the database from version 1 to version 2. After opening the updated app, I checked my original guest records, and they were still there.

Screenshot: `evidence/T1_before.png`

**T2 – Adding Folders and Cards (Passed)**

I created two folders named Atlas and Harbor. I added three cards to Atlas, and they all showed up correctly.

Screenshot: `evidence/T2_cards.png`

**T3 – Editing a Card (Passed)**

I changed a card's title and notes. After pressing Save, the updated information appeared correctly.

**T4 – Deleting a Card (Passed)**

I deleted a card from Atlas. The card disappeared from the list, and the folder's card count decreased by one.

Screenshot: `evidence/T4_after.png`

**T5 – Deleting a Folder (Passed)**

I tested deleting a folder. When I pressed Cancel, the folder stayed there. When I pressed Delete, the folder and its cards were removed.

**T6 – Data Persistence (Passed)**

I closed and reopened the app to check if the information was saved. My folders and cards were still there, and my original guest records from Part I were also still saved.

### Screenshots

- `evidence/T1_before.png`
- `evidence/T2_cards.png`
- `evidence/T4_after.png`

### Code Check

I ran `flutter analyze`, and it showed no errors.

### Conclusion

This lab helped me understand how to upgrade a SQLite database without losing old information. I also learned how to organize records into folders and use Flutter to add, edit, and delete data.