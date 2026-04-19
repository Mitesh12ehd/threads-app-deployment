"use server";


import { revalidatePath } from "next/cache";
// import { currentUser } from "@clerk/nextjs";

import Community from "../models/community.model";
import Thread from "../models/thread.model";
import User from "../models/user.model";

import { connectToDB } from "../mongoose";
import { FilterQuery, SortOrder } from "mongoose";


export async function fetchUser(userId: string) {
  try {
    connectToDB();

    return await User.findOne({ id: userId }).populate({
      path: "communities",
      model: Community,
    });
  } catch (error: any) {
    throw new Error(`Failed to fetch user: ${error.message}`);
  }
}

interface Params {
  userId: string;
  username: string;
  name: string;
  bio: string;
  image: string;
  path: string;
}

export async function updateUser({
  userId,
  bio,
  name,
  path,
  username,
  image,
}: Params): Promise<void> {
  try {
    connectToDB();

    await User.findOneAndUpdate(
      { id: userId },
      {
        username: username.toLowerCase(),
        name,
        bio,
        image,
        onboarded: true,
      },
      { upsert: true }
    );

    if (path === "/profile/edit") {
      revalidatePath(path);
    }
  } catch (error: any) {
    throw new Error(`Failed to create/update user: ${error.message}`);
  }
}

export async function fetchUserPosts(userId: string) {
  try {
    connectToDB();

    // Find all threads authored by the user with the given userId
    const threads = await User.findOne({ id: userId }).populate({
      path: "threads",
      model: Thread,
      populate: [
        {
          path: "community",
          model: Community,
          select: "name id image _id", // Select the "name" and "_id" fields from the "Community" model
        },
        {
          path: "children",
          model: Thread,
          populate: {
            path: "author",
            model: User,
            select: "name image id", // Select the "name" and "_id" fields from the "User" model
          },
        },
      ],
    });
    return threads;
  } catch (error) {
    console.error("Error fetching user threads:", error);
    throw error;
  }
}

// Almost similar to Thead (search + pagination) and Community (search + pagination)
export async function fetchUsers({
  userId,
  searchString = "",
  pageNumber = 1,
  pageSize = 20,
  sortBy = "desc",
}: {
  userId: string;
  searchString?: string;
  pageNumber?: number;
  pageSize?: number;
  sortBy?: SortOrder;
}) {
  try {
    connectToDB();

    // Calculate the number of users to skip based on the page number and page size.
    const skipAmount = (pageNumber - 1) * pageSize;

    // Create a case-insensitive regular expression for the provided search string.
    const regex = new RegExp(searchString, "i");

    // Create an initial query object to filter users.
    const query: FilterQuery<typeof User> = {
      id: { $ne: userId }, // Exclude the current user from the results.
    };

    // If the search string is not empty, add the $or operator to match either username or name fields.
    if (searchString.trim() !== "") {
      query.$or = [
        { username: { $regex: regex } },
        { name: { $regex: regex } },
      ];
    }

    // Define the sort options for the fetched users based on createdAt field and provided sort order.
    const sortOptions = { createdAt: sortBy };

    const usersQuery = User.find(query)
      .sort(sortOptions)
      .skip(skipAmount)
      .limit(pageSize);

    // Count the total number of users that match the search criteria (without pagination).
    const totalUsersCount = await User.countDocuments(query);

    const users = await usersQuery.exec();

    // Check if there are more users beyond the current page.
    const isNext = totalUsersCount > skipAmount + users.length;

    return { users, isNext };
  } catch (error) {
    console.error("Error fetching users:", error);
    throw error;
  }
}

export async function getActivity(userId: string) {

  try {

    connectToDB();

    // Find all threads created by the user
    const userThreads = await Thread.find({ author: userId });

    // Collect all the child thread ids (replies) from the 'children' field of each user thread
    const childThreadIds = userThreads.reduce((acc, userThread) => {
      return acc.concat(userThread.children);
    }, []);

    // Find and return the child threads (replies) excluding the ones created by the same user
    const replies = await Thread.find({
      _id: { $in: childThreadIds },
      author: { $ne: userId }, // Exclude threads authored by the same user
    }).populate({
      path: "author",
      model: User,
      select: "name image _id",
    });

    return replies;
  } catch (error) {
    console.error("Error fetching replies: ", error);
    throw error;
  }
}


export async function sendNotification(id: string, threadId: string, senderId: string) {
  try {
    connectToDB();

    const user = await fetchUser(id);
    const sender = await fetchUser(senderId);

    if (!user) {
      console.log(`User with ID ${user._id} not found.`);
      return;
    }

    // console.log("user notification array", user.notifications);
    // console.log(typeof (user.notifications));

    // check if the thread is already shared
    // eslint-disable-next-line eqeqeq
    const isAlreadyShared = user.notifications.some((notification: {
      senderId: string; threadId: string;
    }) => notification.threadId == threadId && notification.senderId == sender._id);

    if (isAlreadyShared) {
      console.log("Thread is already shared");
      return;
    }

    const payload = {
      type: "message",
      createdAt: Date.now(),
      senderId: sender._id,
      threadId: threadId
    };

    // Push the thread ID into the user's notification array
    user.notifications.push(payload);

    // Save the updated user in the database
    // eslint-disable-next-line no-unused-vars
    const updatedUser = await User.findByIdAndUpdate(user._id, { notifications: user.notifications }, { new: true });

    console.log(`Notification sent to user ${user.name}.`);
  } catch (error) {
    console.error('Error sending notification:', error);
    throw error;
  }
}

export async function getNotification(userId: string) {
  try {
    // Get user's notification array
    const user = await fetchUser(userId);
    if (!user) {
      throw new Error("User not found");
    }

    const notificationArray = user.notifications;

    // Validate array (optional)
    if (!Array.isArray(notificationArray)) {
      throw new Error("Invalid notification array");
    }

    // Sort the notifications array based on createdAt in descending order
    notificationArray.sort((a, b) => b.createdAt - a.createdAt);

    // Filter out only the notifications of type 'message'
    const filteredNotifications = notificationArray.filter(notification => notification.type === 'message');

    console.log("Filtered notification :", filteredNotifications)
    const noti = filteredNotifications.map((notifi) => {
      return notifi.senderId
    })
    console.log("NOTI : ", noti)
    // Fetch details for each sender
    const notificationsWithSenderDetails = await Promise.all(
      filteredNotifications.slice(0, 10).map(async notification => {
        const sender = await User.findById(notification.senderId);
        // console.log("sender Name : ", sender.name)
        return {
          ...notification,
          senderName: sender.name,
          senderImage: sender.image,
        };
      })
    );

    // Return the newest 10 notifications with sender details to the front end
    return notificationsWithSenderDetails;
  } catch (error) {
    console.error('Error fetching notifications:', error);
    throw error;
  }
}


// try {
//   // const result = await User.updateMany({}, { $unset: { notification: 1 } });
//   const result = await User.updateMany([{
//     $addFields: {
//       notifications: [
//         {
//           type: {
//             type: String, // You might have different types of notifications (e.g., 'message', 'like', 'comment', etc.)
//             required: true,
//           },
//           createdAt: {
//             type: Date,
//             default: Date.now,
//           },
//           senderId: {
//             type: mongoose.Schema.Types.ObjectId,
//             required: true,
//             ref: 'User', // Reference to the sender's user document
//           },
//           threadId: {
//             type: mongoose.Schema.Types.ObjectId,
//             required: true,
//             ref: 'Thread',
//           }, // Add this if you want to include a message in the notification
//         },
//       ],
//     }
//   }]);

//   console.log(`${result.modifiedCount} documents updated successfully`);
//   return result.modifiedCount; // Use modifiedCount instead of nModified
// } catch (error) {
//   console.error(error);
//   throw error;
// }

