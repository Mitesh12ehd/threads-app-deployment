import mongoose from "mongoose";

const userSchema = new mongoose.Schema({
  id: {
    type: String,
    required: true,
  },
  username: {
    type: String,
    unique: true,
    required: true,
  },
  name: {
    type: String,
    required: true,
  },
  image: String,
  bio: String,
  threads: [
    {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Thread",
    },
  ],
  onboarded: {
    type: Boolean,
    default: false,
  },
  communities: [
    {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Community",
    },
  ],
  likedPosts: [
    {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Thread",
    }
  ],
  notifications: [
    {
      type: {
        type: String, // You might have different types of notifications (e.g., 'message', 'like', 'comment', etc.)
        required: true,
      },
      createdAt: {
        type: Date,
        default: Date.now,
      },
      senderId: {
        type: mongoose.Schema.Types.ObjectId,
        required: true,
        ref: 'User', // Reference to the sender's user document
      },
      threadId: {
        type: mongoose.Schema.Types.ObjectId,
        required: true,
        ref: 'Thread',
      }, // Add this if you want to include a message in the notification
    },

  ],
});

const User = mongoose.models.User || mongoose.model("User", userSchema);

export default User;
