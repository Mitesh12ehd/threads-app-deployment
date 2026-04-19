"use client";

import Image from "next/image";
// eslint-disable-next-line import/no-duplicates
import { useRouter } from "next/navigation";
// eslint-disable-next-line import/no-duplicates
import { usePathname } from "next/navigation";
import { Button } from "../ui/button";
import { sendNotification } from "@/lib/actions/user.actions";
import { useState } from "react";
import Send from "../ui/Send";

// import { getNotification } from "@/lib/actions/user.actions";

interface Props {
  id: string;
  name: string;
  username: string;
  imgUrl: string;
  personType: string;
  shared?: boolean;
  senderId: string;
}

function UserCard({
  id,
  name,
  username,
  imgUrl,
  personType,
  shared = false,
  senderId,
}: Props) {
  const router = useRouter();
  const pathname = usePathname();
  const threadId = pathname.split("/")[2];
  const [btn, setBtn] = useState(true);
  // after clicking Done button back to home page

  const notificationMoklvu = async (
    id: string,
    threadId: string,
    senderId: string
  ) => {
    setBtn(false);
    await sendNotification(id, threadId, senderId);
  };

  const isCommunity = personType === "Community";

  return (
    <article className="user-card">
      <div className="user-card_avatar">
        <div className="relative h-12 w-12">
          <Image
            src={imgUrl}
            alt="user_logo"
            fill
            className="rounded-full object-cover"
          />
        </div>

        <div className="flex-1 text-ellipsis">
          <h4 className="text-base-semibold text-light-1">{name}</h4>
          <p className="text-small-medium text-gray-1">@{username}</p>
        </div>
      </div>
      {shared ? (
        <Button
          className="user-card_btn"
          onClick={() => {
            notificationMoklvu(id, threadId, senderId);
          }}
        >
          {btn ? "Send" : <Send />}
        </Button>
      ) : (
        <Button
          className="user-card_btn"
          onClick={() => {
            if (isCommunity) {
              router.push(`/communities/${id}`);
            } else {
              router.push(`/profile/${id}`);
            }
          }}
        >
          View
        </Button>
      )}
    </article>
  );
}

export default UserCard;
