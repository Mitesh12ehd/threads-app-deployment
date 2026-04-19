"use client";
import Image from "next/image";
import { Input } from "./ui/input";
import { useSearchParams, usePathname, useRouter } from "next/navigation";

const ShareSearch = () => {
  const searchParams: any = useSearchParams();
  const pathname = usePathname();
  const { replace } = useRouter();

  function handleSearch(terms: string) {
    const params = new URLSearchParams(searchParams);
    if (terms) {
      params.set("query", terms);
    } else {
      params.delete("query");
    }
    replace(`${pathname}?${params.toString()}`);
  }

  return (
    <>
      <div className="searchbar mt-7">
        <Image
          src="/assets/search-gray.svg"
          alt="search"
          width={24}
          height={24}
          className="object-contain"
        />
        <Input
          id="text"
          onChange={(e) => handleSearch(e.target.value)}
          placeholder="Send to..."
          className="no-focus searchbar_input"
          defaultValue={searchParams.get("query")?.toString()}
        />
      </div>
    </>
  );
};

export default ShareSearch;
