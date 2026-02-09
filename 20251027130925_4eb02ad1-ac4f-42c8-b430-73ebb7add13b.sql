-- Create profiles table for admin information
CREATE TABLE public.profiles (
  id UUID NOT NULL REFERENCES auth.users ON DELETE CASCADE PRIMARY KEY,
  admin_name TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

-- Enable RLS
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;

-- Profiles policies
CREATE POLICY "Users can view their own profile"
  ON public.profiles FOR SELECT
  USING (auth.uid() = id);

CREATE POLICY "Users can insert their own profile"
  ON public.profiles FOR INSERT
  WITH CHECK (auth.uid() = id);

-- Create farmers table
CREATE TABLE public.farmers (
  farmer_id TEXT NOT NULL PRIMARY KEY,
  farmer_name TEXT NOT NULL,
  animal_type TEXT NOT NULL CHECK (animal_type IN ('Cow', 'Buffalo')),
  contact_info TEXT NOT NULL,
  created_by UUID REFERENCES auth.users NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

ALTER TABLE public.farmers ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can view farmers"
  ON public.farmers FOR SELECT
  USING (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can create farmers"
  ON public.farmers FOR INSERT
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Authenticated users can update farmers"
  ON public.farmers FOR UPDATE
  USING (auth.uid() = created_by);

CREATE POLICY "Authenticated users can delete farmers"
  ON public.farmers FOR DELETE
  USING (auth.uid() = created_by);

-- Create animals table
CREATE TABLE public.animals (
  animal_id TEXT NOT NULL PRIMARY KEY,
  farmer_id TEXT NOT NULL REFERENCES public.farmers(farmer_id) ON DELETE CASCADE,
  animal_type TEXT NOT NULL CHECK (animal_type IN ('Cow', 'Buffalo')),
  created_by UUID REFERENCES auth.users NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

ALTER TABLE public.animals ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can view animals"
  ON public.animals FOR SELECT
  USING (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can create animals"
  ON public.animals FOR INSERT
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Authenticated users can update animals"
  ON public.animals FOR UPDATE
  USING (auth.uid() = created_by);

CREATE POLICY "Authenticated users can delete animals"
  ON public.animals FOR DELETE
  USING (auth.uid() = created_by);

-- Create staff table
CREATE TABLE public.staff (
  staff_id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  staff_name TEXT NOT NULL,
  staff_age INTEGER NOT NULL,
  gender TEXT NOT NULL CHECK (gender IN ('Male', 'Female', 'Other')),
  qualification TEXT NOT NULL,
  contact_info TEXT NOT NULL,
  created_by UUID REFERENCES auth.users NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

ALTER TABLE public.staff ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can view staff"
  ON public.staff FOR SELECT
  USING (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can create staff"
  ON public.staff FOR INSERT
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Authenticated users can update staff"
  ON public.staff FOR UPDATE
  USING (auth.uid() = created_by);

CREATE POLICY "Authenticated users can delete staff"
  ON public.staff FOR DELETE
  USING (auth.uid() = created_by);

-- Create milk_sales table
CREATE TABLE public.milk_sales (
  sale_id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  farmer_id TEXT NOT NULL REFERENCES public.farmers(farmer_id) ON DELETE CASCADE,
  milk_quantity DECIMAL(10, 2) NOT NULL,
  price_per_liter DECIMAL(10, 2) NOT NULL DEFAULT 50.00,
  total_amount DECIMAL(10, 2) NOT NULL,
  sale_date DATE NOT NULL DEFAULT CURRENT_DATE,
  created_by UUID REFERENCES auth.users NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

ALTER TABLE public.milk_sales ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can view milk sales"
  ON public.milk_sales FOR SELECT
  USING (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can create milk sales"
  ON public.milk_sales FOR INSERT
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Authenticated users can update milk sales"
  ON public.milk_sales FOR UPDATE
  USING (auth.uid() = created_by);

CREATE POLICY "Authenticated users can delete milk sales"
  ON public.milk_sales FOR DELETE
  USING (auth.uid() = created_by);

-- Create products table
CREATE TABLE public.products (
  product_id UUID NOT NULL DEFAULT gen_random_uuid() PRIMARY KEY,
  product_name TEXT NOT NULL,
  quantity DECIMAL(10, 2) NOT NULL,
  price_per_unit DECIMAL(10, 2) NOT NULL,
  total_price DECIMAL(10, 2) NOT NULL,
  sale_date DATE NOT NULL DEFAULT CURRENT_DATE,
  created_by UUID REFERENCES auth.users NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT now()
);

ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Authenticated users can view products"
  ON public.products FOR SELECT
  USING (auth.role() = 'authenticated');

CREATE POLICY "Authenticated users can create products"
  ON public.products FOR INSERT
  WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Authenticated users can update products"
  ON public.products FOR UPDATE
  USING (auth.uid() = created_by);

CREATE POLICY "Authenticated users can delete products"
  ON public.products FOR DELETE
  USING (auth.uid() = created_by);

-- Create trigger function for profile creation
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public
AS $$
BEGIN
  INSERT INTO public.profiles (id, admin_name)
  VALUES (new.id, new.raw_user_meta_data->>'admin_name');
  RETURN new;
END;
$$;

-- Trigger to create profile on user signup
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();