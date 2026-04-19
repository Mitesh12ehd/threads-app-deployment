"use client";
import Image from "next/image";
import { useState } from "react";

import {
  addLikeToThreads,
  unLikeToThreads,
} from "@/lib/actions/thread.actions";

interface props {
  threadId: string;
  currentUserId: string;
  liked: boolean;
  totallike: number;
}

const Liking = ({ threadId, currentUserId, liked, totallike }: props) => {
  const [like, setLike] = useState(liked);
  const [totalLike, setTotalLike] = useState(totallike);

  const addLikeToPost = async (threadId: string, currentUserId: string) => {
    let responese;

    if (like) {
      responese = await unLikeToThreads(threadId, currentUserId);
      if (responese) {
        setLike(false);
        setTotalLike(responese.totalLike);
      }
    } else {
      responese = await addLikeToThreads(threadId, currentUserId);
      if (responese) {
        setLike(true);
        setTotalLike(responese.totalLike);
      }
    }

    return responese;
  };
  return (
    <div className="flex gap-2">
      <Image
        src={like ? "/assets/heart-filled.svg" : "/assets/heart-gray.svg"}
        alt="heart"
        width={24}
        height={24}
        className=" cursor-pointer object-contain"
        onClick={() => addLikeToPost(threadId, currentUserId)}
      />
      {Number(totalLike) > 0 && (
        // eslint-disable-next-line tailwindcss/no-custom-classname
        <span className="w-1 text-gray-500">{totalLike}</span>
      )}
    </div>
  );
};

export default Liking;
