'use client';

import React, { useState } from 'react';
import { MessageCircle, CheckCircle2 } from 'lucide-react';

export function HomeConsultationSection() {
  const [name, setName] = useState('');
  const [phone, setPhone] = useState('');
  const [project, setProject] = useState('كمبوند الأندلس ريزيدنس');
  const [submitted, setSubmitted] = useState(false);

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!name || !phone) return;
    setSubmitted(true);
    setTimeout(() => {
      setSubmitted(false);
      setName('');
      setPhone('');
    }, 4000);
  };

  return (
    <section id="contact" className="py-16 sm:py-24 bg-[#242424] text-white">
      <div className="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div className="grid grid-cols-1 lg:grid-cols-12 gap-10 items-center">
          <div className="lg:col-span-6 space-y-5">
            <span className="text-xs font-bold uppercase tracking-widest text-[#A89F91]">
              استشارة استثمارية خاصة
            </span>
            <h2 className="font-editorial text-3xl sm:text-5xl font-black text-[#F4F4F2] leading-tight">
              احصل على دراسة تفصيلية لوحدتك القادمة
            </h2>
            <p className="text-sm text-[#A89F91] leading-relaxed">
              فريق مستشارينا الماليين والمعماريين جاهز لتزويدك بكافة المخططات الهندسية، جداول السداد المعتمدة، وفرص الاستثمار المتاحة.
            </p>
          </div>

          <div className="lg:col-span-6">
            <div className="rounded-3xl bg-[#1E1E1E] border border-[#333333] p-6 sm:p-8 shadow-xl">
              {submitted ? (
                <div className="text-center py-10 space-y-3">
                  <div className="w-14 h-14 rounded-full bg-[#A89F91]/20 text-[#A89F91] flex items-center justify-center mx-auto">
                    <CheckCircle2 className="w-8 h-8" />
                  </div>
                  <h4 className="text-lg font-bold text-[#F4F4F2]">تم إرسال طلبك بنجاح</h4>
                  <p className="text-xs text-[#A89F91]">
                    سيتواصل معك أحد مسؤولي المبيعات خلال ساعات العمل الرسمية.
                  </p>
                </div>
              ) : (
                <form onSubmit={handleSubmit} className="space-y-4">
                  <div>
                    <label className="text-xs font-bold text-[#F4F4F2] block mb-1.5">
                      الاسم بالكامل
                    </label>
                    <input
                      type="text"
                      required
                      value={name}
                      onChange={e => setName(e.target.value)}
                      placeholder="أدخل اسمك الكريم"
                      className="w-full px-4 py-3 rounded-xl bg-[#242424] border border-[#333333] text-xs font-semibold text-white placeholder-[#777777] focus:outline-none focus:border-[#A89F91] transition"
                    />
                  </div>

                  <div>
                    <label className="text-xs font-bold text-[#F4F4F2] block mb-1.5">
                      رقم الهاتف / الواتساب
                    </label>
                    <input
                      type="tel"
                      required
                      value={phone}
                      onChange={e => setPhone(e.target.value)}
                      placeholder="010xxxxxxxx"
                      dir="ltr"
                      className="w-full px-4 py-3 rounded-xl bg-[#242424] border border-[#333333] text-xs font-semibold text-white placeholder-[#777777] focus:outline-none focus:border-[#A89F91] transition text-right"
                    />
                  </div>

                  <div>
                    <label className="text-xs font-bold text-[#F4F4F2] block mb-1.5">
                      المشروع محل الاهتمام
                    </label>
                    <select
                      value={project}
                      onChange={e => setProject(e.target.value)}
                      className="w-full px-4 py-3 rounded-xl bg-[#242424] border border-[#333333] text-xs font-semibold text-white focus:outline-none focus:border-[#A89F91] transition"
                    >
                      <option value="كمبوند الأندلس ريزيدنس">كمبوند الأندلس ريزيدنس (التجمع الخامس)</option>
                      <option value="برج النيل بلازا">برج النيل بلازا (كورنيش المعادي)</option>
                      <option value="عمارة الياسمين الراقية">عمارة الياسمين الراقية (الشيخ زايد)</option>
                    </select>
                  </div>

                  <button
                    type="submit"
                    className="w-full py-3.5 rounded-xl bg-[#A89F91] hover:bg-[#968D7F] text-[#242424] font-black text-xs transition duration-200 shadow-md active:scale-95"
                  >
                    إرسال طلب الاستشارة المجانية
                  </button>
                </form>
              )}
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}
