import type { Metadata } from "next";
import "./globals.css";

export const metadata: Metadata = {
  title: "عقار المصريين | El Masryeen - الصرح العقاري الذكي ونظام المحاسبة",
  description: "منصة عقار المصريين: واجهة معمارية راقية، حاسبة الأقساط، وبوابة إدارة المحاسبة العقارية الاحترافية",
};

export default function RootLayout({
  children,
}: {
  children: React.ReactNode;
}) {
  return (
    <html lang="ar" dir="rtl" className="h-full antialiased">
      <head>
        <link rel="preconnect" href="https://fonts.googleapis.com" />
        <link rel="preconnect" href="https://fonts.gstatic.com" crossOrigin="anonymous" />
        <link
          href="https://fonts.googleapis.com/css2?family=Cairo:wght@300;400;500;600;700;800;900&family=Newsreader:ital,opsz,wght@0,6..72,300..800;1,6..72,300..800&family=Plus+Jakarta+Sans:wght@300;400;500;600;700;800&display=swap"
          rel="stylesheet"
        />
      </head>
      <body className="min-h-full flex flex-col font-sans bg-[#F4F4F2] text-[#242424]">
        {children}
      </body>
    </html>
  );
}
