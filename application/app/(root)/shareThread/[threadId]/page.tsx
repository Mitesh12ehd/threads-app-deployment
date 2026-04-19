import { fetchThreadById } from "@/lib/actions/thread.actions";
import ThreadCard from "@/components/cards/ThreadCard";
import { currentUser } from "@clerk/nextjs";
import { fetchUser, fetchUsers } from "@/lib/actions/user.actions";
import UserCard from "@/components/cards/UserCard";
import ShareSearch from "@/components/ShareSearch";

async function page({
  params,
  searchParams,
}: {
  params: { threadId: string };
  searchParams: {
    query: string;
    searchParams: {
      query: string | undefined;
    };
  };
}) {
  const query: string = searchParams?.query || "";

  const user = await currentUser();

  if (!user) {
    return null;
  }

  const userInfo = await fetchUser(user.id);
  const Thread = await fetchThreadById(params.threadId);

  if (!Thread) {
    return null;
  }

  let result;
  if (query) {
    result = await fetchUsers({
      userId: user.id,
      searchString: query,
    });
  } else {
    result = await fetchUsers({
      userId: user.id,
      pageSize: 8,
    });
  }

  return (
    <div className="flex flex-col  text-white">
      <ThreadCard
        key={Thread._id}
        id={Thread._id}
        currentUserId={user.id}
        parentId={Thread.parentId}
        content={Thread.text}
        author={Thread.author}
        community={Thread.community}
        createdAt={Thread.createdAt}
        comments={Thread.children}
        liked={Thread.likes.includes(userInfo._id)}
        totalLike={Thread.likes.length}
      />
      <ShareSearch />

      <div className="mt-14 flex flex-col gap-9">
        {result?.users.length === 0 ? (
          <p className="no-result">No Result</p>
        ) : (
          <>
            {result?.users.map((person) => (
              <UserCard
                key={person.id}
                id={person.id}
                name={person.name}
                username={person.username}
                imgUrl={person.image}
                personType="User"
                shared
                senderId={user.id}
              />
            ))}
          </>
        )}
      </div>
    </div>
  );
}

export default page;
