"use client";
// Import React and other necessary dependencies
import { useRouter } from "next/navigation";
import Image from "next/image";
import { Input } from "../ui/input";
import { useEffect, useState } from "react";

// Define the Props interface
interface Props {
  routeType: string;
}

// Define the Searchbar component
function Searchbar({ routeType }: Props) {
  // Use `next/router` to get the router object
  const router = useRouter();
  const [search, setSearch] = useState("");

  // useEffect to handle the delayed search
  useEffect(() => {
    const delayDebounceFn = setTimeout(() => {
      // Use the `next/router` object to push the new URL
      if (search) {
        router.push(`/${routeType}?q=${search}`);
      } else {
        router.push(`/${routeType}`);
      }
    }, 300);

    // Cleanup function to clear the timeout
    return () => clearTimeout(delayDebounceFn);
  }, [search, routeType, router]); // Include `router` in the dependency array

  // Return the JSX for the Searchbar component
  return (
    <div className="searchbar">
      <Image
        src="/assets/search-gray.svg"
        alt="search"
        width={24}
        height={24}
        className="object-contain"
      />
      <Input
        id="text"
        value={search}
        onChange={(e) => setSearch(e.target.value)}
        placeholder={`${
          routeType !== "/search" ? "Search communities" : "Search creators"
        }`}
        className="no-focus searchbar_input"
      />
    </div>
  );
}

// Export the Searchbar component as the default export
export default Searchbar;
