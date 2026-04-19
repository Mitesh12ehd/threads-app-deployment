import Image from "next/image";
import Link from "next/link";
import { currentUser } from "@clerk/nextjs";
import { redirect } from "next/navigation";

import {
  fetchUser,
  getActivity,
  getNotification,
} from "@/lib/actions/user.actions";

async function Page() {
  const user = await currentUser();
  if (!user) return null;

  const userInfo = await fetchUser(user.id);
  if (!userInfo?.onboarded) redirect("/onboarding");

  const notifications = await getNotification(user.id);
  const activity = await getActivity(userInfo._id);

  return (
    <>
      <h1 className="head-text">Activity</h1>

      <section className="mt-5 flex flex-col gap-5">
        <h2 className="text-heading3-bold text-light-1">Shared Threads : </h2>
        {activity.length || notifications.length > 0 ? (
          <>
            {notifications.map((notification: any) => (
              <Link
                key={notification._id}
                href={`/thread/${notification._doc.threadId}`}
              >
                <article className="activity-card">
                  <Image
                    src={notification.senderImage}
                    alt="user_logo"
                    width={20}
                    height={20}
                    className="rounded-full object-cover"
                  />
                  <p className="!text-small-regular text-light-1">
                    <span className="mr-1 text-primary-500">
                      {notification.senderName}
                    </span>{" "}
                    Share Thread With You
                  </p>
                </article>
              </Link>
            ))}
          </>
        ) : (
          <p className="!text-base-regular text-light-3">No activity yet</p>
        )}
      </section>

      <section className="mt-10 flex flex-col gap-5">
        <h2 className="text-heading3-bold text-light-1">
          Comments On Your Threads :{" "}
        </h2>
        {activity.length || notifications.length > 0 ? (
          <>
            {activity.map((activity) => (
              <Link key={activity._id} href={`/thread/${activity.parentId}`}>
                <article className="activity-card">
                  <Image
                    src={activity.author.image}
                    alt="user_logo"
                    width={20}
                    height={20}
                    className="rounded-full object-cover"
                  />
                  <p className="!text-small-regular text-light-1">
                    <span className="mr-1 text-primary-500">
                      {activity.author.name}
                    </span>{" "}
                    replied to your thread
                  </p>
                </article>
              </Link>
            ))}
          </>
        ) : (
          <p className="!text-base-regular text-light-3">No activity yet</p>
        )}
      </section>
    </>
  );
}

export default Page;
